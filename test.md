# 🌏 AI Travel Agent — Full System Design Guide

> A production-grade guide for building a state-aware, tool-calling AI travel concierge that handles discovery, booking, payment, and post-sale customer service — entirely through conversation.

**Stack:** Claude API · LangGraph · FastAPI · PostgreSQL · Redis · Stripe

---

## Table of Contents

1. [Project Vision](#1-project-vision)
2. [System Architecture](#2-system-architecture)
3. [Tech Stack](#3-tech-stack)
4. [Conversation State Machine](#4-conversation-state-machine)
5. [The 7 Agent Stages](#5-the-7-agent-stages)
6. [Complete Tool Catalog](#6-complete-tool-catalog)
7. [Tool JSON Schemas](#7-tool-json-schemas)
8. [Database Design](#8-database-design)
9. [Security Layer](#9-security-layer)
10. [Edge Cases — Real World Handling](#10-edge-cases--real-world-handling)
11. [Backend Setup](#11-backend-setup)
12. [Frontend Setup](#12-frontend-setup)
13. [System Prompt Design](#13-system-prompt-design)
14. [10-Week Build Roadmap](#14-10-week-build-roadmap)
15. [Pre-Launch Checklist](#15-pre-launch-checklist)

---

## 1. Project Vision

### What You Are Building

A **stateful AI agent** that knows where the user is in the booking journey, calls real APIs, handles edge cases, and secures the entire payment flow — not a linear chatbot.

### Core Philosophy

> Real users don't follow a script. They change their mind, ask random questions, go silent for 3 days, then come back. Your system must handle all of this gracefully without losing context or data integrity.

| ❌ What NOT to build | ✅ What you ARE building |
|---|---|
| A linear chatbot that asks one question at a time | A stateful AI agent that knows the current booking stage |
| No memory between messages | Full conversation memory with 7-day session persistence |
| Hallucinated trip results | Tool-verified data only — AI cannot invent prices or bookings |
| One-shot payment flow | Multi-step secure payment with webhook verification |
| Breaks when user says something unexpected | Graceful edge case handling for every real-world scenario |

---

## 2. System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    USER (Browser / Mobile App)              │
└──────────────────────────┬──────────────────────────────────┘
                           │ WebSocket / HTTPS
┌──────────────────────────▼──────────────────────────────────┐
│                     FRONTEND LAYER                          │
│          React Chat UI  │  Image Viewer  │  QR Display      │
└──────────────────────────┬──────────────────────────────────┘
                           │ REST / WebSocket
┌──────────────────────────▼──────────────────────────────────┐
│                  API GATEWAY (FastAPI)                       │
│   Auth Middleware  │  Rate Limiter  │  Input Sanitizer       │
└──────┬──────────────────────────────────────┬───────────────┘
       │                                      │
┌──────▼────────────┐              ┌──────────▼──────────────┐
│   AGENT ENGINE    │              │   WEBHOOK RECEIVER       │
│  LangGraph FSM    │              │   (Stripe Events)        │
│  Tool Dispatcher  │              │   Payment Verifier       │
│  Memory Manager   │              └──────────────────────────┘
└──────┬────────────┘
       │
┌──────▼──────────────────────────────────────────────────────┐
│                      TOOL LAYER                             │
│  Travel APIs  │  Image Gen  │  Weather  │  Payment APIs     │
└──────┬──────────────────────────────────────────────────────┘
       │
┌──────▼──────────────────────────────────────────────────────┐
│                     DATA LAYER                              │
│  PostgreSQL (bookings, users)  │  Redis (session state)    │
└─────────────────────────────────────────────────────────────┘
```

> **Key Design Rule:** The AI model never has direct database access. All data operations go through backend service functions (tools). This prevents hallucination from affecting real data and keeps your security layer intact.

---

## 3. Tech Stack

| Layer | Technology | Reason |
|---|---|---|
| AI Model | Claude claude-sonnet-4-20250514 + Tool Calling | Best-in-class instruction following and tool use |
| Agent Framework | LangGraph | State machines built for complex agent flows |
| Backend | Python 3.11+ · FastAPI · Pydantic v2 | Fast, async, type-safe |
| Session State | Redis with TTL | Sub-millisecond session reads, automatic expiry |
| Database | PostgreSQL · SQLAlchemy · Alembic | Reliable, transactional, production-proven |
| Travel APIs | Amadeus API · Google Places API | Real flight/hotel data with free sandbox tiers |
| Images | Google Places Photos · Unsplash (fallback) | High quality, no copyright issues |
| Payment | Stripe · Stripe Webhooks | Industry standard, QR payment support |
| Weather | OpenWeatherMap API | Free tier sufficient for production |
| Frontend | React 18 · Tailwind CSS · WebSockets | Real-time streaming, component-based UI |
| Auth | JWT (access + refresh tokens) · bcrypt | Stateless auth with secure token handling |
| Deploy | Docker + Docker Compose · Railway or Render | Easy start, scales when needed |

---

## 4. Conversation State Machine

This is the heart of your system. Every message is processed in the context of a **current state**. The AI knows what stage the conversation is in and behaves accordingly.

```
DISCOVERY → SUGGESTION → EXPLORATION → CUSTOMIZATION → BOOKING → PAYMENT → POST_BOOKING
```

> **Important:** States can go backwards. A user in BOOKING state can say "actually, can you change the hotel?" and the system must transition back to EXPLORATION. Design every state transition — not just the happy path.

### State Model (Stored in Redis per Session)

```python
class ConversationState:
    session_id: str
    user_id: str
    state: AgentState  # enum: DISCOVERY, SUGGESTION, EXPLORATION...

    # Extracted from discovery
    mood: str | None
    environment: str | None       # mountain, beach, city, forest, island
    duration_days: int | None
    people_count: int | None
    budget_min: float | None
    budget_max: float | None
    departure_city: str | None
    travel_dates: dict | None

    # Selected options
    suggested_trips: list[Trip]
    selected_trip_id: str | None
    customizations: list[str]

    # Booking info
    booking_id: str | None
    payment_intent_id: str | None
    payment_status: str | None

    # Conversation history
    messages: list[Message]       # last 20 messages for context window
    created_at: datetime
    last_active: datetime
```

---

## 5. The 7 Agent Stages

### Stage 1 — Discovery: Understanding the User

**Goal:** Extract everything the AI needs before making a single suggestion.

**Required fields before suggesting:**
- Mood / emotional state
- Environment preference (mountain, beach, city...)
- Duration in days
- Number of people
- Budget range
- Departure city

**Real user inputs to handle:**

```
"I feel stressed and want somewhere cold, maybe mountain, 2 days with girlfriend."
"Somewhere not too expensive, I don't care where, just relaxing"
"I want luxury but my budget is $80"      ← conflicting, ask which matters more
"Not sure on dates yet"                   ← okay to proceed, ask for approximate
```

> **Rule:** Never call `getTripSuggestions()` until mood, duration, people count, budget, and departure city are all confirmed. Never assume missing values.

**Tools:** `extractTravelIntent()` · `validateRequiredFields()`

---

### Stage 2 — Suggestion: Three Smart Options

**Always return exactly 3 options** with different price tiers and different vibes.

Each suggestion must include:
- Trip title
- Short emotional tagline
- Price per person
- Duration
- What is included / excluded
- Top 3 highlights

After presenting options, always ask:

> *"Would you like to see the itinerary, images, hotel details, compare options, or change budget?"*

This naturally opens the Exploration stage.

**Tools:** `getTripSuggestions()` · `calculatePrice()`

---

### Stage 3 — Exploration: Answer Everything

The user drills into details. Dispatch the correct tool based on what they ask. Multiple tool calls can run in a single response — if a user asks "show me hotel AND weather" that is 2 parallel tool calls.

| User says | Tool called |
|---|---|
| "Show me the itinerary" | `getTripItinerary()` |
| "What hotel is included?" | `getHotelDetails()` |
| "Show me photos" | `getTripImages()` |
| "Can I change to 3 days?" | `calculateCustomTrip()` |
| "What's the weather like?" | `getWeatherForecast()` |
| "Compare option 1 and 2" | `compareTrips()` |
| "Is it safe there?" | AI answers from knowledge + getHotelDetails() |
| "What if it rains?" | `getWeatherForecast()` + AI reasoning |

**Tools:** `getTripItinerary()` · `getHotelDetails()` · `getTripImages()` · `getWeatherForecast()` · `compareTrips()` · `calculateCustomTrip()`

---

### Stage 4 — Customization: Make It Theirs

The user wants personal touches. AI recalculates the total after each change and presents a clear updated summary.

```
User: "Can we make it more romantic?"

AI calls: customizeTrip({ add: ["private_dinner", "hotel_upgrade", "sunset_cruise"] })

AI responds: "I've upgraded this to a private romantic package.
             New total is $320 for 2 people. Would you like to proceed?"
```

**Handles:** upgrade hotel, add private dinner, change transport, add an extra night, apply discount code, negotiate price, request group discount.

> **Important:** If the customization pushes over the user's stated budget, warn them before asking to proceed.

**Tools:** `customizeTrip()` · `calculatePrice()` · `applyDiscountCode()` · `getHotelDetails()`

---

### Stage 5 — Booking: Collect and Confirm

Booking must NEVER be one-shot. Three clear steps:

**Step 1: Confirm details**
AI summarizes: trip name, dates, people count, total price, what is included. Asks: *"Shall I book this for you?"*

**Step 2: Collect required info**
- Full name
- Phone number
- Pickup location
- Special requests (dietary needs, accessibility, etc.)

Validate each field before proceeding.

**Step 3: Create the reservation**
Call `createBooking()` → returns a Booking ID and a 15-minute hold expiry.

> **Critical:** The booking status is `RESERVED`, not `CONFIRMED`. It does not become confirmed until payment succeeds via webhook.

**Tools:** `createBooking()` · `validateUserDetails()`

---

### Stage 6 — Payment: Controlled and Safe

```
AI: "Your booking is reserved for 15 minutes. Scan the QR code to complete payment."

[QR Code displayed in chat]

User pays via Stripe checkout page
        ↓
Stripe fires: payment_intent.succeeded webhook
        ↓
Backend verifies signature + amount match
        ↓
Backend updates booking to CONFIRMED
        ↓
Backend notifies agent via Redis pub/sub
        ↓
AI: "Payment confirmed 🎉 Your trip is officially booked!"
```

> **Never trust the frontend to report payment success.** Always verify on the backend via Stripe webhook. The frontend can lie. Webhooks cannot be faked without your secret key.

If the QR timer expires: regenerate a new payment intent and new QR code with fresh 15-minute window.

**Tools:** `generatePaymentQR()` · `checkPaymentStatus()`

---

### Stage 7 — Post-Booking: Real Customer Service

This is where most systems stop. Yours does not.

**The AI stays active for the full customer lifecycle:**

- Send trip reminder (1 day before)
- Send weather update before departure
- Offer travel insurance upsell
- Offer add-on packages
- Answer any pre-trip questions
- Handle cancellation requests (check policy → auto-refund if eligible)
- Handle reschedule requests
- Check refund status for user

**Tools:** `cancelBooking()` · `modifyBooking()` · `getWeatherForecast()` · `refundPayment()`

---

## 6. Complete Tool Catalog

| Tool | HTTP Method | Description |
|---|---|---|
| `getTripSuggestions()` | GET /api/trips/suggest | Returns 3 options based on user preferences |
| `getTripDetails()` | GET /api/trips/{id}/details | Full itinerary, inclusions, hotel info |
| `getTripImages()` | GET /api/trips/{id}/images | 4–6 image URLs for the destination |
| `getTripItinerary()` | GET /api/trips/{id}/itinerary | Day-by-day activity, meals, transport breakdown |
| `getHotelDetails()` | GET /api/hotels/{id} | Name, stars, amenities, room type, policy |
| `getWeatherForecast()` | GET /api/weather/{destination} | 7-day forecast via OpenWeatherMap |
| `compareTrips()` | POST /api/trips/compare | Side-by-side comparison of 2–3 options |
| `calculateCustomTrip()` | POST /api/trips/calculate | Recalculate when duration or people changes |
| `customizeTrip()` | POST /api/trips/{id}/customize | Apply add-ons: hotel upgrade, dinner, transport |
| `applyDiscountCode()` | POST /api/discounts/apply | Validate promo code, return new price |
| `createBooking()` | POST /api/bookings | Create PENDING reservation with 15-min hold |
| `generatePaymentQR()` | POST /api/payments/qr | Create Stripe Payment Intent, return QR URL |
| `checkPaymentStatus()` | GET /api/payments/{id}/status | Poll current status: pending / succeeded / failed |
| `cancelBooking()` | DELETE /api/bookings/{id} | Cancel + trigger refund logic per policy |
| `modifyBooking()` | POST /api/bookings/{id}/modify | Reschedule or change booking details |
| `refundPayment()` | POST /api/payments/refund | Initiate Stripe refund (full or partial) |

---

## 7. Tool JSON Schemas

These are the exact definitions you pass to the Claude API in the `tools` parameter.

```python
# tools.py — Tool schemas for Claude API

TRAVEL_TOOLS = [
  {
    "name": "getTripSuggestions",
    "description": """Search for trip packages based on user preferences.
    Call this ONLY after collecting all required info:
    mood, environment, budget, duration, people count, and departure city.""",
    "input_schema": {
      "type": "object",
      "properties": {
        "mood": {
          "type": "string",
          "description": "User's emotional state, e.g. 'stressed', 'adventurous', 'romantic'"
        },
        "environment": {
          "type": "string",
          "enum": ["mountain", "beach", "city", "forest", "island"]
        },
        "duration_days": {
          "type": "integer",
          "minimum": 1,
          "maximum": 30
        },
        "people_count": {
          "type": "integer",
          "minimum": 1
        },
        "budget_usd": {
          "type": "object",
          "properties": {
            "min": {"type": "number"},
            "max": {"type": "number"}
          },
          "required": ["min", "max"]
        },
        "departure_city": {"type": "string"}
      },
      "required": ["mood", "environment", "duration_days", "people_count", "budget_usd", "departure_city"]
    }
  },
  {
    "name": "createBooking",
    "description": """Create a booking reservation.
    ONLY call after the user explicitly confirms they want to book
    AND all required personal details are collected and validated.""",
    "input_schema": {
      "type": "object",
      "properties": {
        "trip_id": {"type": "string"},
        "customer_name": {"type": "string"},
        "customer_phone": {"type": "string"},
        "pickup_location": {"type": "string"},
        "travel_date": {"type": "string", "format": "date"},
        "special_requests": {"type": "string"},
        "customizations": {"type": "array", "items": {"type": "string"}}
      },
      "required": ["trip_id", "customer_name", "customer_phone", "pickup_location", "travel_date"]
    }
  }
  # ... add all 16 tools following the same pattern
]
```

---

## 8. Database Design

### PostgreSQL — Persistent Data

```sql
-- Users
CREATE TABLE users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone       VARCHAR(20) UNIQUE NOT NULL,
  name        VARCHAR(100),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Trip packages (your product catalog)
CREATE TABLE trips (
  id                UUID PRIMARY KEY,
  title             VARCHAR(200),
  destination       VARCHAR(100),
  duration_days     INTEGER,
  price_per_person  NUMERIC(10,2),
  includes          JSONB,      -- array of inclusions
  excludes          JSONB,
  itinerary         JSONB,      -- day-by-day schedule
  hotel_id          UUID,
  is_active         BOOLEAN DEFAULT true
);

-- Bookings
CREATE TABLE bookings (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID REFERENCES users(id),
  trip_id          UUID REFERENCES trips(id),
  status           VARCHAR(20) DEFAULT 'PENDING',
                   -- PENDING | RESERVED | CONFIRMED | CANCELLED | REFUNDED
  total_price      NUMERIC(10,2),
  customizations   JSONB,
  travel_date      DATE,
  pickup_location  VARCHAR(200),
  special_requests TEXT,
  reserved_until   TIMESTAMPTZ,  -- 15-minute payment window
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Payments
CREATE TABLE payments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id        UUID REFERENCES bookings(id),
  stripe_intent_id  VARCHAR(100) UNIQUE,
  amount            NUMERIC(10,2),
  currency          VARCHAR(3) DEFAULT 'USD',
  status            VARCHAR(20),    -- pending | succeeded | failed
  stripe_event_id   VARCHAR(100),   -- for idempotency (never process twice)
  paid_at           TIMESTAMPTZ,
  refunded_at       TIMESTAMPTZ,
  refund_amount     NUMERIC(10,2)
);
```

### Redis — Session State

```
# Conversation session (TTL: 7 days — allows return after long absence)
session:{session_id}  →  JSON ConversationState

# Booking hold (TTL: 15 minutes — auto-expires unpaid reservations)
booking_hold:{booking_id}  →  "1"

# Payment event channel (pub/sub — notifies agent when payment succeeds)
payment_events:{user_id}  →  pub/sub channel

# Rate limiting per user per endpoint
rate:{user_id}:{endpoint}  →  request count (TTL: 60s)
```

---

## 9. Security Layer

### Core Rules — Never Break These

- Never let the AI write SQL directly
- Never trust payment status from the frontend
- Never expose API keys to the browser
- Never store raw credit card data (Stripe handles this)
- Never skip Stripe webhook signature verification
- Never process the same payment webhook twice

### Input Validation with Pydantic

```python
# Every tool call input is validated before execution
from pydantic import BaseModel, validator

class CreateBookingInput(BaseModel):
    trip_id: str
    customer_name: str
    customer_phone: str
    travel_date: date

    @validator('customer_name')
    def name_must_be_clean(cls, v):
        if len(v) < 2 or len(v) > 100:
            raise ValueError('Name must be 2–100 characters')
        if not v.replace(' ', '').isalpha():
            raise ValueError('Name must contain only letters')
        return v.strip()

    @validator('customer_phone')
    def phone_must_be_valid(cls, v):
        import re
        if not re.match(r'^\+?[\d\s\-]{8,15}$', v):
            raise ValueError('Invalid phone number')
        return v
```

### Stripe Webhook Verification

```python
# CRITICAL: Always verify webhook signatures before processing
@app.post("/webhooks/stripe")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, STRIPE_WEBHOOK_SECRET
        )
    except stripe.error.SignatureVerificationError:
        # Reject any unverified webhook immediately
        raise HTTPException(status_code=400)

    # Idempotency check — never process the same event twice
    if await payment_already_processed(event["id"]):
        return {"status": "already_processed"}

    if event["type"] == "payment_intent.succeeded":
        await confirm_booking(event["data"]["object"])

    return {"status": "ok"}
```

### Rate Limits

| Endpoint | Limit | Window |
|---|---|---|
| /api/chat | 30 requests | 1 minute |
| /api/payments/* | 5 requests | 1 minute |
| /api/bookings | 3 requests | 1 minute |
| /api/trips/suggest | 10 requests | 1 minute |
| /auth/* | 5 requests | 5 minutes |

---

## 10. Edge Cases — Real World Handling

### User Disappears Mid-Booking

Session is saved in Redis with a 7-day TTL. When the user returns, load the session. If a booking was `RESERVED` but unpaid, check if the 15-minute hold expired. If expired, notify the user and offer to re-confirm. Never lose conversation history.

```python
async def handle_message(session_id: str, message: str):
    # Load session from Redis
    session = await redis.get(f"session:{session_id}")

    if not session:
        session = ConversationState(state=AgentState.DISCOVERY)
    else:
        session = ConversationState(**json.loads(session))

        if session.state == AgentState.PAYMENT:
            if await booking_hold_expired(session.booking_id):
                # Hold expired while user was away
                session.state = AgentState.BOOKING
                session.booking_id = None
                # AI will inform user and ask to re-confirm

    response = await agent.process(session, message)

    # Save updated session (reset 7-day TTL on every message)
    await redis.setex(
        f"session:{session_id}",
        604800,  # 7 days
        session.model_dump_json()
    )
    return response
```

### Payment Failed

Stripe returns a failure webhook event. AI notifies user immediately. Regenerate a new QR with a fresh 15-minute window. Log the failure with the Stripe error code. After 3 consecutive failures, set a flag to escalate to human support.

### User Wants Refund After Payment

AI checks the cancellation policy stored in the trip record. If within the free cancellation window, automatically initiate a Stripe refund. If past the window, show the policy and the partial refund amount. Never issue a refund without a policy check.

### Budget Conflict

```
User: "I want something cheap but 5-star."

AI: "Those two usually pull in opposite directions — which matters more to you right now,
     keeping costs low, or the quality of the hotel and experience?
     That will help me find the best match."
```

Never silently pick one. Surface the conflict and ask.

### AI Hallucination Guard

Your system prompt must explicitly state:

```
You cannot invent trip options, prices, hotel names, or booking confirmations.
All data must come from tool call results only.
If a tool call fails or returns an error, tell the user honestly
and offer to try again or suggest alternatives.
```

---

## 11. Backend Setup

### Project Structure

```
travel-agent/
├── backend/
│   ├── main.py                 # FastAPI app entry point
│   ├── agent/
│   │   ├── agent.py            # Core agent loop
│   │   ├── tools.py            # All tool functions (execute real logic)
│   │   ├── tool_schemas.py     # JSON schemas for Claude API
│   │   └── prompts.py          # System prompt builder
│   ├── api/
│   │   ├── chat.py             # WebSocket endpoint
│   │   ├── bookings.py         # Booking CRUD routes
│   │   └── payments.py         # Stripe + webhook routes
│   ├── services/
│   │   ├── travel_service.py   # Amadeus + Google Places integration
│   │   ├── payment_service.py  # Stripe logic
│   │   └── weather_service.py  # OpenWeatherMap integration
│   ├── models/                 # SQLAlchemy ORM models
│   ├── schemas/                # Pydantic request/response schemas
│   └── config.py               # Settings from environment variables
├── frontend/
│   └── src/
│       ├── components/
│       │   ├── ChatWindow.jsx
│       │   ├── MessageBubble.jsx
│       │   ├── TripCard.jsx
│       │   ├── ImageGallery.jsx
│       │   └── QRPayment.jsx
│       └── hooks/
│           └── useWebSocket.js
├── docker-compose.yml
└── .env
```

### Core Agent Loop

```python
# agent/agent.py
import anthropic
import json

client = anthropic.Anthropic()

async def run_agent(session: ConversationState, user_message: str) -> str:
    # Add user message to history
    session.messages.append({"role": "user", "content": user_message})

    while True:
        # Call Claude with current conversation + injected state context
        response = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2048,
            system=build_system_prompt(session),
            messages=session.messages[-20:],   # last 20 to stay within context window
            tools=TRAVEL_TOOLS
        )

        # AI decided to call a tool
        if response.stop_reason == "tool_use":
            tool_results = []
            for block in response.content:
                if block.type == "tool_use":
                    # Execute tool on YOUR backend — not by the AI
                    result = await execute_tool(block.name, block.input, session)
                    tool_results.append({
                        "type": "tool_result",
                        "tool_use_id": block.id,
                        "content": json.dumps(result)
                    })

            # Feed results back into the conversation
            session.messages.append({"role": "assistant", "content": response.content})
            session.messages.append({"role": "user", "content": tool_results})
            # Loop again — AI will now form its final response

        else:
            # AI is done — extract and return the text
            ai_text = "".join(b.text for b in response.content if b.type == "text")
            session.messages.append({"role": "assistant", "content": ai_text})
            return ai_text
```

---

## 12. Frontend Setup

### Message Type System

The backend sends structured message types — not just plain strings. The frontend renders each type as the appropriate UI component.

```javascript
// Type: "text" — plain AI message
{ type: "text", content: "Here are 3 options for your trip..." }

// Type: "trip_cards" — rendered as clickable cards
{ type: "trip_cards", trips: [
  { id: "t1", title: "Bokor Mountain Escape", price: 89, duration: 2,
    tagline: "Cold air, misty views, total peace", highlights: [...] }
]}

// Type: "image_gallery" — rendered as image grid
{ type: "image_gallery", destination: "Bokor Mountain", images: [url1, url2, url3] }

// Type: "payment_qr" — rendered with countdown timer
{ type: "payment_qr", qr_url: "...", amount: 178,
  booking_id: "...", expires_at: "2024-..." }

// Type: "booking_confirmed" — rendered as confirmation card
{ type: "booking_confirmed", booking_id: "...",
  trip: {...}, travel_date: "..." }
```

### WebSocket Real-time Connection

```javascript
// hooks/useWebSocket.js
const useAgentWebSocket = (sessionId) => {
  const [messages, setMessages] = useState([]);
  const [isTyping, setIsTyping] = useState(false);

  const ws = useRef(new WebSocket(`wss://api.yourapp.com/ws/${sessionId}`));

  ws.current.onmessage = (event) => {
    const data = JSON.parse(event.data);

    if (data.type === "typing_start") setIsTyping(true);
    if (data.type === "typing_end")   setIsTyping(false);

    if (data.type === "message") {
      setMessages(prev => [...prev, data.payload]);
      setIsTyping(false);
    }

    if (data.type === "payment_confirmed") {
      // Show celebration animation + booking details card
    }
  };
};
```

---

## 13. System Prompt Design

The system prompt is **injected dynamically** — it changes based on the current conversation state. This keeps the AI focused and prevents it from taking inappropriate actions for the current stage.

```python
# agent/prompts.py

def build_system_prompt(session: ConversationState) -> str:
    base = f"""You are an AI travel concierge agent for [Company Name].
You help users plan and book trips through natural conversation.

CRITICAL RULES:
- Never invent trip data, prices, or booking IDs. All data comes from tool results only.
- Never confirm a booking before createBooking() returns a booking_id.
- Never confirm payment before receiving a webhook-verified confirmation.
- Never ask more than one question per response.
- Sound human, warm, and helpful — never robotic.
- If a tool fails, tell the user honestly and offer alternatives.

Current State: {session.state}
Departure City: {session.departure_city or 'Not yet collected'}
Selected Trip: {session.selected_trip_id or 'None'}
Booking ID: {session.booking_id or 'None'}
"""

    state_instructions = {
        "DISCOVERY": """
Your goal: Understand what the user wants to experience.
Ask naturally, one question at a time.
Required fields: mood, environment, duration, people count, budget, departure city.
Do NOT call getTripSuggestions() until ALL 6 fields are confirmed.
If budget is vague ('not too expensive'), ask: 'Are you thinking under $100, $100–200, or more?'
""",
        "SUGGESTION": """
Present exactly 3 trip options in a clear, emotional way.
After presenting, ask: 'Would you like the itinerary, images, hotel info, or to compare these?'
Do not push for booking yet. Let the user explore first.
""",
        "EXPLORATION": """
Answer whatever the user asks about the trips.
You may call multiple tools in one response if the user asks multiple things.
If the user selects a trip, update the selected_trip_id in session and move to CUSTOMIZATION or BOOKING.
""",
        "BOOKING": """
Guide the user through the 3-step booking process:
1. Summarize and confirm details
2. Collect: full name, phone, pickup location, special requests
3. Call createBooking() — never before steps 1 and 2 are complete
The booking status will be RESERVED, not CONFIRMED, until payment succeeds.
""",
        "PAYMENT": """
The QR code has been shown. Do not generate a new one unless the user says payment failed.
The booking is RESERVED but NOT CONFIRMED until webhook verification succeeds.
If the user asks 'did it go through?' — call checkPaymentStatus(), do not guess.
If QR expired, call generatePaymentQR() again to get a fresh one.
""",
        "POST_BOOKING": """
The booking is confirmed. Act as ongoing customer support.
You can help with: questions about the trip, weather updates, cancellations, reschedules, add-ons.
Always check cancellation policy before initiating any refund.
"""
    }

    return base + state_instructions.get(session.state, "")
```

---

## 14. 10-Week Build Roadmap

Build in strict order. Each week produces a working, testable outcome before moving forward.

### Week 1 — Learn AI Tool Calling
Build a tiny Python script with Claude and 2 fake tools (`fakeSearchTrips`, `fakeGetWeather`). Make Claude decide when to call each one. Get comfortable with the tool use loop. This teaches you the foundation of everything else.

### Week 2 — Project Setup + State Machine
Create the FastAPI project. Set up PostgreSQL and Redis with Docker Compose. Implement the `ConversationState` model. Build session save/load with Redis. Write the core agent loop without real tools yet.

### Week 3 — Discovery + Suggestion Stages
Write the system prompt with state injection. Implement `extractTravelIntent()` and `getTripSuggestions()` with mock data. Test 10 different user input styles. Handle vague, conflicting, and incomplete inputs until they all work.

### Week 4 — Exploration Stage + Real APIs
Connect Amadeus API (use their free sandbox). Implement `getWeatherForecast()` with OpenWeatherMap. Add `getTripImages()` with Google Places Photos. Test the "user drills into details" flow thoroughly.

### Week 5 — Customization Stage
Implement `customizeTrip()` and `calculatePrice()`. Build the trip modification system. Test all these user requests: "make it more romantic", "add private dinner", "upgrade the hotel", "apply my discount code".

### Week 6 — Booking Stage + Database
Create real PostgreSQL tables. Implement `createBooking()` with PENDING status and 15-minute Redis hold. Build `validateUserDetails()`. Test the full data collection flow. Confirm booking IDs are real, stored, and traceable.

### Week 7 — Payment Stage
Set up Stripe in test mode. Implement `generatePaymentQR()`. Build the webhook endpoint with signature verification and idempotency checks. Test payment success, failure, expiry, and double-webhook scenarios.

### Week 8 — Frontend Chat UI
Build the React chat interface with WebSocket connection. Implement message type renderers: trip cards, image gallery, QR display, booking confirmation card. Add typing indicator and streaming text.

### Week 9 — Edge Cases + Post-Booking
Implement cancel, modify, and refund flows. Add session resume logic for returning users. Build the post-booking AI support system. Stress test: user returns after 3 days, payment fails 3 times, user changes mind after payment.

### Week 10 — Security Hardening + Deploy
Add rate limiting to all endpoints. Enable full Pydantic input validation on every tool. Add audit logging for all financial events. Docker build and deploy on Railway or Render. Switch Stripe from test to live mode.

---

## 15. Pre-Launch Checklist

### AI Quality
- [ ] AI never invents trips, prices, or booking IDs
- [ ] AI uses correct state transitions for all flows
- [ ] System prompt is injected dynamically per state
- [ ] All tool results are passed back before AI responds
- [ ] Hallucination guard clause is in system prompt

### Payment Safety
- [ ] Stripe webhook signature verification is enabled
- [ ] Idempotency keys used on all Stripe calls
- [ ] Payment amount verified server-side against booking amount
- [ ] Refund policy is enforced by backend, not AI
- [ ] QR expiry is enforced via Redis TTL

### Data Integrity
- [ ] All DB writes are inside transactions
- [ ] Session state is saved after every message
- [ ] Booking holds expire correctly via Redis TTL
- [ ] All financial events logged with timestamps and Stripe event IDs

### Security
- [ ] All endpoints have rate limiting
- [ ] JWT tokens expire and refresh correctly
- [ ] All user inputs validated with Pydantic before tool execution
- [ ] API keys are in environment variables only — never in code
- [ ] HTTPS enforced on all endpoints

### Monitoring
- [ ] Error alerts configured (Sentry recommended)
- [ ] Payment failures trigger team notifications
- [ ] Expired unpaid bookings are tracked and logged
- [ ] API uptime monitoring is active

### Real User Testing
- [ ] Tested with 5 real users who don't know the system
- [ ] Observed where users get confused and fixed it
- [ ] Tested unexpected inputs ("what's the meaning of life?")
- [ ] Tested all edge cases: session return, payment failure, refund flow

---

> **Final note:** This system — built correctly — can become a serious product. The combination of natural language booking, real payment processing, and genuine post-sale AI support is rare in the market. Focus on quality over speed. Get the agent right first, then scale.
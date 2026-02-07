# Screens Directory

## Role
This directory contains the screen-level widgets for the application.

## Rules
- **Parent Rules**: Adhere to the rules defined in [../README.md](../README.md).

## Implementation Guidelines
- **New Screen**: Create a new directory for the screen if it involves multiple files.
  - Implement as a `StatefulWidget` or `StatelessWidget`.
- **New Reusable Widget**: If a widget is reused across multiple screens, place it in a `widgets` directory or the `theme` directory if it's a theme component.

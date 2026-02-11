phase 1: check the backend_nestjs and make sure  the backend_nesjs and connect bakong_payment and after that test the both service and find vulerability
phase2: read the frontend (das_tern_mcp) and update the interface for payment so first you can the upgrade to premium and then you can also when user click let user select paymen method(visa card, local payment- bakong payment) when user click bakong payment list the  description and then when user click upgrade it must show the qrcode to the user and they scan it when they paid must reposne to the user payment is successfully. 

read the business logic for more understand the premium 

docs
 

business_logic


***flw architecture*** 
- the bakong_payment just working as the response  for api to the main backend (backend_nestjs). 
- bakong do not connect to the database  in the docker reasson: bakong_payment will host in separate vps and backend_nestjs and other service will host in another one vps. so to handle with this you can create the data (small database for working this bakong payment) both bakong_payment and bakong_db will in one vps. 
- bakong just response to main backend(backend_nestjs) service the service when the main backend needed. 
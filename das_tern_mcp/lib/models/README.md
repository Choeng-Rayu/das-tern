# Note

In this folder is about the models of the app. so when you want to add a new model create the new file and name the model file name should be in namelCase, please add it to the `mobile_app/lib/models` folder base on this model structure.


As a AI agent you can imrpove and create the new model if needed or this model is missing something is not accurate. the goal of this implemennt this mode is focus on scalable in the futre. 

## Model Structure
```
📦models
 ┣ 📂enums_model
 ┃ ┗ 📜README.md
 ┣ 📂users_models
 ┃ ┣ 📂doctor_model
 ┃ ┃ ┣ 📜README.md
 ┃ ┃ ┗ 📜doctor.dart
 ┃ ┣ 📂patient_model
 ┃ ┃ ┣ 📜README.md
 ┃ ┃ ┗ 📜patient.dart
 ┃ ┣ 📜README.md
 ┃ ┗ 📜user.dart
 ┗ 📜README.md
```

## Future Implementation 
 This Application will add the new like scaning prescription and auto generate the reminder.

 ocr_service for scannign prescription.
 
 add AI-llm-service for make the prescription is more accurate and understandable prescription in the better way.

# Rules
## Important
1. One model should have one file not one file model have mony models. 
2. File name should be in same as model name.
## Model Rules

1. Create the new model in the `mobile_app/lib/models` folder and name the model file name should be in namelCase.
2. Create the new enum in the `mobile_app/lib/models/enums_model` folder and name the enum file name should be in namelCase.
3. Create the new model in the `mobile_app/lib/models/users_models` folder and name the model file name should be in namelCase.
4. Create the new model in the `mobile_app/lib/models/users_models/doctor_model` folder and name the model file name should be in namelCase.
5. Create the new model in the `mobile_app/lib/models/users_models/patient_model` folder and name the model file name should be in namelCase.
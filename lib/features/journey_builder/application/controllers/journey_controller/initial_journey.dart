import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';

// Initial state creator to populate "Motor Insurance" as seen in the mockup
JourneyConfig getInitialJourney() {
  return JourneyConfig(
    journeyName: "Motor Insurance Journey",
    version: "1.0.0",
    steps: [
      JourneyStep(
        id: "personal",
        title: "Personal Details",
        description: "Please provide your basic information",
        nextStep: "vehicle",
        fields: [
          InputComponent(
            id: "fullName",
            label: "Full Name",
            type: "text",
            required: true,
            placeholder: "Enter full name",
          ),
          InputComponent(
            id: "dob",
            label: "Date of Birth",
            type: "date",
            required: true,
            placeholder: "DD/MM/YYYY",
          ),
          InputComponent(
            id: "mobile",
            label: "Mobile Number",
            type: "phone",
            required: true,
            placeholder: "Enter mobile number",
          ),
          InputComponent(
            id: "email",
            label: "Email Address",
            type: "text",
            required: false,
            placeholder: "Enter email address",
          ),
          OptionsComponent(
            id: "gender",
            label: "Gender",
            type: "radio",
            required: true,
            options: const ["Male", "Female", "Other"],
            defaultValue: "Male",
          ),
          OptionsComponent(
            id: "maritalStatus",
            label: "Marital Status",
            type: "dropdown",
            required: false,
            placeholder: "Select marital status",
            options: const ["Single", "Married", "Divorced", "Widowed"],
          ),
          InputComponent(
            id: "address",
            label: "Address",
            type: "textarea",
            required: false,
            placeholder: "Enter your current address",
          ),
        ],
        validations: [
          StepValidation(
            type: "required",
            field: "fullName",
            message: "Full Name is required",
          ),
          StepValidation(
            type: "required",
            field: "mobile",
            message: "Mobile number is required",
          ),
          StepValidation(
            type: "required",
            field: "dob",
            message: "Date of Birth is required",
          ),
        ],
        conditions: [
          StepCondition(
            type: "visibleIf",
            field: "gender",
            operator: "equals",
            value: "Female",
          ),
          StepCondition(
            type: "enableIf",
            field: "email",
            operator: "contains",
            value: "@",
          ),
        ],
        apiCalls: [
          StepAPI(
            method: "POST",
            url: "/api/v1/personal-info",
            description: "Save personal details info",
          ),
        ],
        actions: [
          StepAction(
            trigger: "onSubmit",
            actionType: "apiCall",
            details: "Submit personal details",
          ),
        ],
        screenLayout: const {
          "id": "root-scaffold",
          "type": "Column",
          "properties": {
            "mainAxisAlignment": "start",
            "crossAxisAlignment": "stretch",
          },
          "styles": {"padding": 16.0},
          "children": [
            {
              "id": "banner_image",
              "type": "Image",
              "properties": {"label": "Banner Image"},
              "styles": {
                "src":
                    "https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?w=800",
                "height": 160.0,
                "borderRadius": 12.0,
                "margin": {"bottom": 16.0},
              },
              "children": [],
              "actions": [],
            },
            {
              "id": "details_card",
              "type": "Card",
              "properties": {},
              "styles": {
                "elevation": 4.0,
                "backgroundColor": "#FFFFFF",
                "borderRadius": 16.0,
                "padding": 16.0,
                "margin": {"bottom": 16.0},
              },
              "children": [
                {
                  "id": "card_header_row",
                  "type": "Row",
                  "properties": {
                    "mainAxisAlignment": "space_between",
                    "crossAxisAlignment": "center",
                  },
                  "styles": {},
                  "children": [
                    {
                      "id": "card_title",
                      "type": "Text",
                      "properties": {"label": "Motor Insurance Details"},
                      "styles": {
                        "fontSize": 18.0,
                        "fontWeight": "bold",
                        "color": "#1A1A2E",
                      },
                      "children": [],
                      "actions": [],
                    },
                    {
                      "id": "card_badge",
                      "type": "Badge",
                      "properties": {"label": "Step 1 of 4"},
                      "styles": {
                        "backgroundColor": "#E8E7FD",
                        "textColor": "#5B4FCF",
                      },
                      "children": [],
                      "actions": [],
                    },
                  ],
                  "actions": [],
                },
                {
                  "id": "card_divider",
                  "type": "Divider",
                  "properties": {},
                  "styles": {
                    "height": 1.0,
                    "color": "#E5E7EB",
                    "margin": {"top": 12.0, "bottom": 12.0},
                  },
                  "children": [],
                  "actions": [],
                },
                {
                  "id": "fullName_field",
                  "type": "TextField",
                  "properties": {
                    "fieldName": "fullName",
                    "label": "Full Name",
                    "hint": "Enter full name",
                    "required": true,
                  },
                  "styles": {},
                  "children": [],
                  "actions": [],
                },
                {
                  "id": "phone_dob_row",
                  "type": "Row",
                  "properties": {
                    "mainAxisAlignment": "start",
                    "crossAxisAlignment": "start",
                  },
                  "styles": {},
                  "children": [
                    {
                      "id": "mobile_expanded",
                      "type": "Expanded",
                      "properties": {},
                      "styles": {},
                      "children": [
                        {
                          "id": "mobile_field",
                          "type": "TextField",
                          "properties": {
                            "fieldName": "mobile",
                            "label": "Mobile Number",
                            "hint": "Enter mobile number",
                            "required": true,
                          },
                          "styles": {},
                          "children": [],
                          "actions": [],
                        },
                      ],
                      "actions": [],
                    },
                    {
                      "id": "dob_expanded",
                      "type": "Expanded",
                      "properties": {},
                      "styles": {},
                      "children": [
                        {
                          "id": "dob_field",
                          "type": "DatePicker",
                          "properties": {
                            "fieldName": "dob",
                            "label": "Date of Birth",
                            "hint": "DD/MM/YYYY",
                            "required": true,
                          },
                          "styles": {},
                          "children": [],
                          "actions": [],
                        },
                      ],
                      "actions": [],
                    },
                  ],
                  "actions": [],
                },
                {
                  "id": "email_field",
                  "type": "TextField",
                  "properties": {
                    "fieldName": "email",
                    "label": "Email Address",
                    "hint": "Enter email address",
                    "required": false,
                  },
                  "styles": {},
                  "children": [],
                  "actions": [],
                },
                {
                  "id": "gender_field",
                  "type": "Radio",
                  "properties": {
                    "fieldName": "gender",
                    "label": "Gender",
                    "options": ["Male", "Female", "Other"],
                  },
                  "styles": {},
                  "children": [],
                  "actions": [],
                },
              ],
              "actions": [],
            },
            {
              "id": "notice_box",
              "type": "Container",
              "properties": {},
              "styles": {
                "borderRadius": 12.0,
                "padding": 12.0,
                "gradientStart": "#5B4FCF",
                "gradientEnd": "#8B5CF6",
                "margin": {"bottom": 16.0},
              },
              "children": [
                {
                  "id": "notice_row",
                  "type": "Row",
                  "properties": {
                    "mainAxisAlignment": "start",
                    "crossAxisAlignment": "center",
                  },
                  "styles": {},
                  "children": [
                    {
                      "id": "notice_icon",
                      "type": "Icon",
                      "properties": {"icon": "info"},
                      "styles": {"fontSize": 20.0, "color": "#FFFFFF"},
                      "children": [],
                      "actions": [],
                    },
                    {
                      "id": "notice_text",
                      "type": "Text",
                      "properties": {
                        "label":
                            " Provide correct details to get instant policy quotes.",
                      },
                      "styles": {"fontSize": 12.0, "color": "#FFFFFF"},
                      "children": [],
                      "actions": [],
                    },
                  ],
                  "actions": [],
                },
              ],
              "actions": [],
            },
            {
              "id": "submit_btn",
              "type": "Button",
              "properties": {"label": "Continue to Vehicle Details"},
              "styles": {
                "backgroundColor": "#5B4FCF",
                "textColor": "#FFFFFF",
                "borderRadius": 8.0,
                "elevation": 3.0,
              },
              "children": [],
              "actions": [
                {
                  "event": "onTap",
                  "steps": [
                    {
                      "id": "step_validate_1",
                      "type": "validate",
                      "enabled": true,
                    },
                    {
                      "id": "step_navigate_1",
                      "type": "navigate",
                      "enabled": true,
                      "pageId": "vehicle",
                    },
                  ],
                },
              ],
            },
          ],
        },
      ),
      JourneyStep(
        id: "vehicle",
        title: "Vehicle Details",
        description: "Please provide vehicle information",
        nextStep: "nominee",
        fields: [
          InputComponent(
            id: "vehicleNum",
            label: "Vehicle Number",
            type: "text",
            required: true,
            placeholder: "e.g. MH-12-AB-1234",
          ),
          OptionsComponent(
            id: "vehicleMake",
            label: "Make",
            type: "dropdown",
            required: true,
            placeholder: "Select manufacturer",
            options: const ["Toyota", "Honda", "Hyundai", "Suzuki", "Tata"],
          ),
          InputComponent(
            id: "vehicleModel",
            label: "Model",
            type: "text",
            required: true,
            placeholder: "Enter vehicle model",
          ),
          OptionsComponent(
            id: "regYear",
            label: "Registration Year",
            type: "dropdown",
            required: true,
            placeholder: "Select registration year",
            options: const ["2026", "2025", "2024", "2023", "2022", "2021", "2020"],
          ),
        ],
      ),
      JourneyStep(
        id: "nominee",
        title: "Nominee Details",
        description: "Provide nominee description for coverage",
        nextStep: "documents",
        fields: [
          InputComponent(
            id: "nomineeName",
            label: "Nominee Full Name",
            type: "text",
            required: true,
            placeholder: "Enter nominee name",
          ),
          OptionsComponent(
            id: "nomineeRelation",
            label: "Relationship",
            type: "dropdown",
            required: true,
            placeholder: "Select relationship",
            options: const ["Spouse", "Father", "Mother", "Son", "Daughter"],
          ),
        ],
      ),
      JourneyStep(
        id: "documents",
        title: "Upload Documents",
        description: "Upload necessary documents",
        nextStep: "review",
        fields: [
          InputComponent(
            id: "panDoc",
            label: "PAN Card",
            type: "file",
            required: true,
          ),
          InputComponent(
            id: "drivingLicense",
            label: "Driving License",
            type: "file",
            required: true,
          ),
        ],
      ),
      JourneyStep(
        id: "review",
        title: "Review & Confirm",
        description: "Review your submitted data",
        nextStep: "payment",
        fields: [
          OptionsComponent(
            id: "termsAccepted",
            label: "I accept the policy terms and declarations",
            type: "switch",
            required: true,
            defaultValue: "false",
          ),
        ],
      ),
      JourneyStep(
        id: "payment",
        title: "Payment",
        description: "Enter premium payment details",
        nextStep: "success",
        fields: [
          OptionsComponent(
            id: "paymentMethod",
            label: "Select Payment Mode",
            type: "radio",
            required: true,
            options: const ["Credit Card", "Debit Card", "UPI", "Net Banking"],
            defaultValue: "Credit Card",
          ),
          InputComponent(
            id: "otpVerify",
            label: "Verification Code",
            type: "otp",
            required: true,
            placeholder: "Enter 6-digit OTP",
          ),
        ],
      ),
      JourneyStep(
        id: "success",
        title: "Success",
        description: "Your policy generated successfully!",
        fields: [
          LayoutComponent(
            id: "successDiv",
            label: "Congratulations! Policy PDF has been sent to your email.",
            type: "divider",
          ),
        ],
      ),
    ],
  );
}

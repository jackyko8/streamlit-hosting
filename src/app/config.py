# Common configuration of the application

Config = {
    # CloudFront Access Control for the Streamlit app
    "SecretHeader": "X-Client-Secret",
    "SecretValue": "secret-value",

    # Replace with your own CSS style sheet
    "CSS": """
        <style>
        /* Make the main content background light gray */
        .stApp {
            background-color: #f7f7f7;
        }

        /* Center the title and subheader */
        .stMarkdown h1, .stMarkdown h2 {
            text-align: center;
            color: #ff4b4b;
        }

        /* Style buttons */
        .stButton > button {
            background-color: #008CBA; /* Blue background */
            color: white; /* White text */
            font-size: 16px;
            border-radius: 8px;
            padding: 10px 20px;
        }

        .stButton > button:hover {
            background-color: #005f73; /* Darker blue on hover */
        }

        /* Style text inputs */
        .stTextInput > div > div > input {
            border: 2px solid #ff4b4b;
            border-radius: 5px;
        }

        /* Style sidebar */
        .stSidebar {
            background-color: #eeeeee;
        }

        /* Customize metric display */
        .stMetric {
            background-color: #ddd;
            padding: 10px;
            border-radius: 10px;
            text-align: center;
        }
        </style>
""",
    # Add more configuration items as required
}

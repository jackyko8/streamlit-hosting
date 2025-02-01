import os
import json

import streamlit as st
from streamlit_javascript import st_javascript

from config import *

st.set_page_config(
    page_title="My Streamlit App",  # Title that appears in the browser tab
    page_icon="🔆",  # Favicon that appears in the browser tab
)

# For CloudFront Access Control only
# if config_secret_required and st.context.headers.get(config_secret_key) != config_secret_value:
#     st.error("Access Denied")
#     st.stop()

url = st_javascript("await fetch('').then(r => window.parent.location.href)")

st.write("<div style='text-align: center; font-weight: bold; font-size: 30px;'>My Streamlit App</div>", unsafe_allow_html=True)
st.write(f"<div style='text-align: center; font-weight: bold; font-size: 20px;'>{url}</div>", unsafe_allow_html=True)
st.write("<div style='text-align: center; font-size: 16px;'>You may press R to refresh.</div>", unsafe_allow_html=True)

st.write(f"""
{config_css}
<a name='top'></a>
""",
    unsafe_allow_html=True
)

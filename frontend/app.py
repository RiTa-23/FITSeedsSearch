import streamlit as st
import requests
import pandas as pd

import os

API_URL = os.getenv("API_URL", "http://localhost:8000/search")

@st.cache_data(ttl=60)
def search_seeds(query):
    response = requests.get(API_URL, params={"q": query}, timeout=10)
    response.raise_for_status()
    return response.json()

# Initialize session state for search results
if "search_results" not in st.session_state:
    st.session_state.search_results = None

st.set_page_config(page_title="FIT Seeds Search", layout="wide")

st.title("FIT Seeds Search")
st.markdown("Search across research proposals by keyword.")

# Search Input
# Search Input
with st.form("search_form"):
    query = st.text_input("Enter keyword (e.g. '5G', 'AI', 'Robotics')", "")
    submitted = st.form_submit_button("Search")

if submitted and query:
    try:
        data = search_seeds(query)
        st.session_state.search_results = data
    except requests.exceptions.ConnectionError:
        st.error("Could not connect to the backend API. Is it running?")
        st.session_state.search_results = None
    except Exception as e:
        st.error(f"An error occurred: {e}")
        st.session_state.search_results = None

# Display results from session state
if st.session_state.search_results is not None:
    data = st.session_state.search_results
    
    if data:
        st.success(f"Found {len(data)} results")
        
        # Convert to DataFrame for better display
        df = pd.DataFrame(data)
        
        # Selecting and renaming columns for display
        display_cols = {
            "project_title": "Project Title",
            "researcher_name": "Researcher",
            "research_field": "Field",
            "description": "Description"
        }
        
        # Filter columns that exist in the dataframe
        cols_to_show = [c for c in display_cols.keys() if c in df.columns]
        df_display = df[cols_to_show].rename(columns=display_cols)
        
        st.dataframe(df_display, use_container_width=True)
        
        with st.expander("View Raw Details"):
            for item in data:
                st.write(item)
                st.divider()
    else:
        st.warning("No results found.")

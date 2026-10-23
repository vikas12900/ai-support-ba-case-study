import streamlit as st
from bot import ask

st.set_page_config(page_title="NorthPeak Bank support (demo)")
st.title("NorthPeak Bank support assistant")
st.caption("Demo with a fictional bank. You are chatting with an AI assistant. "
           "It hands you to a human agent when it should.")

if "history" not in st.session_state:
    st.session_state.history = []

for message in st.session_state.history:
    st.chat_message(message["role"]).write(message["content"])

question = st.chat_input("Ask about cards, fees or top-ups")

if question:
    st.chat_message("user").write(question)
    reply = ask(question, st.session_state.history)

    with st.chat_message("assistant"):
        st.write(reply.answer)
        if reply.sources:
            st.caption("Sources: " + ", ".join(reply.sources))
        if reply.escalate:
            st.warning("Handed off to a human agent: " + reply.escalation_reason)

    st.session_state.history.append({"role": "user", "content": question})
    st.session_state.history.append({"role": "assistant", "content": reply.answer})

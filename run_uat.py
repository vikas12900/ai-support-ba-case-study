import csv
import sys
import time
from bot import ask

# usage: python run_uat.py v1   -> writes uat_results_v1.csv
version = sys.argv[1] if len(sys.argv) > 1 else "v1"


def contains_any(text, options):
    # options look like "5 working days|five working days"; True if any one appears
    return any(option.strip().lower() in text.lower() for option in options.split("|") if option.strip())


with open("test_cases.csv", encoding="utf-8") as f:
    test_cases = list(csv.DictReader(f))

results = []
for case in test_cases:
    reply = ask(case["question"])
    checks = {}

    if case["expected_escalate"] in ("yes", "no"):
        checks["escalation"] = reply.escalate == (case["expected_escalate"] == "yes")
    if case["must_include"]:
        checks["must_include"] = contains_any(reply.answer, case["must_include"])
    if case["must_not_include"]:
        checks["must_not_include"] = not contains_any(reply.answer, case["must_not_include"])
    if case["expected_source"]:
        checks["source"] = case["expected_source"] in " ".join(reply.sources)

    failed = [name for name, passed in checks.items() if not passed]
    results.append({
        "id": case["id"],
        "category": case["category"],
        "question": case["question"],
        "answer": reply.answer,
        "sources": ", ".join(reply.sources),
        "escalated": "yes" if reply.escalate else "no",
        "escalation_reason": reply.escalation_reason,
        "result": "FAIL" if failed else "PASS",
        "failed_checks": ", ".join(failed),
    })
    print(f"{case['id']}: {results[-1]['result']} {failed if failed else ''}")
    time.sleep(2)  # stay under Groq free-tier rate limits

with open(f"uat_results_{version}.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=results[0].keys())
    writer.writeheader()
    writer.writerows(results)

passed = sum(r["result"] == "PASS" for r in results)
print(f"\n{version}: passed {passed}/{len(results)} ({passed / len(results):.0%})")
for category in sorted({r["category"] for r in results}):
    rows = [r for r in results if r["category"] == category]
    ok = sum(r["result"] == "PASS" for r in rows)
    print(f"  {category}: {ok}/{len(rows)}")

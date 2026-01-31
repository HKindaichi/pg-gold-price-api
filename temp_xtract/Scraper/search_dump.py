
def search_context():
    keywords = ["Selling", "Buying", "Daily Price", "Gold Price", "Price *"]
    with open("cimb_dump.html", "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    with open("context.txt", "w", encoding="utf-8") as out:
        for i, line in enumerate(lines):
            for kw in keywords:
                if kw.lower() in line.lower():
                    out.write(f"--- Found '{kw}' at line {i+1} ---\n")
                    start = max(0, i - 10)
                    end = min(len(lines), i + 20)
                    for j in range(start, end):
                        out.write(f"{j+1}: {lines[j].strip()}\n")
                    out.write("-------------------------------\n")
    print("Context saved to context.txt")

if __name__ == "__main__":
    search_context()

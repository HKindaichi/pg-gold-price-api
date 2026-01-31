
def find():
    target = "2,239.43"
    with open("cimb_dump.html", "r", encoding="utf-8") as f:
        for i, line in enumerate(f):
            if target in line:
                print(f"Found on line {i+1}: {line.strip()}")
                return i+1
if __name__ == "__main__":
    find()

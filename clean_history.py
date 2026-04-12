import os

file_path = 'output/history.csv'
if os.path.exists(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    clean_lines = []
    header = "timestamp,merchant,item,sell,buy,spread\n"
    clean_lines.append(header)
    
    count = 0
    for line in lines:
        line_str = line.strip()
        if not line_str or line_str.startswith('timestamp'): continue
        if line_str.startswith('<<<<<<<') or line_str.startswith('=======') or line_str.startswith('>>>>>>>'):
            continue
        
        parts = line_str.split(',')
        if len(parts) == 6: # Hanya ambil baris dengan 6 kolum tepat
            clean_lines.append(line_str + '\n')
            count += 1
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(clean_lines)
    print(f"Berjaya mengekalkan {count} baris data yang sah. Membuang data rosak.")
else:
    print("Fail tidak dijumpai.")

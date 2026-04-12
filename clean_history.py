import os

file_path = 'output/history.csv'
if os.path.exists(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    clean_lines = []
    header = "timestamp,merchant,item,sell,buy,spread\n"
    clean_lines.append(header)
    
    removed_count = 0
    for line in lines:
        line_str = line.strip()
        if not line_str or line_str.startswith('timestamp'): continue
        if any(marker in line_str for marker in ['<<<<', '====', '>>>>']): continue
        
        parts = line_str.split(',')
        if len(parts) == 6:
            try:
                sell = float(parts[3])
                buy = float(parts[4])
                # Price cutoff: RM 2,000 is impossible for now
                if sell < 2000 and buy < 2000:
                    clean_lines.append(line_str + '\n')
                else:
                    removed_count += 1
            except ValueError:
                removed_count += 1
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(clean_lines)
    print(f"Pembersihan Selesai. {removed_count} baris data rosak/melampau dibuang.")
else:
    print("Fail tidak dijumpai.")

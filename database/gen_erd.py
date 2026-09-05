# -*- coding: utf-8 -*-
# توليد مخطط ERD بصيغة SVG — نسخة 2 محسّنة (ارتفاعات تلقائية + مسارات نظيفة)
import html

GAP = 20
HEAD_H = 96
ACCENT = "#0284C7"
EDGE = "#94A3B8"
FONT = "Tahoma, 'Segoe UI', sans-serif"

domains = [
 ("1️⃣ الإدارة والتحكم — Tenancy & RBAC", [
   ("institutes المعاهد", ["id, slug (نطاق فرعي لكل معهد)", "name, plan, currency, is_active"], "#0F172A"),
   ("branches الفروع", ["id, institute_id FK", "name, address, phone"], "#1E293B"),
   ("rooms القاعات", ["id, branch_id FK", "capacity, equipment"], "#1E293B"),
   ("users المستخدمون", ["id, role (8 أدوار RBAC)", "institute_id FK"], "#1E293B"),
   ("audit_logs سجل التدقيق", ["من فعل ماذا ومتى (JSONB)"], "#334155"),
 ]),
 ("2️⃣ الأشخاص — People", [
   ("students الطلاب ⭐", ["code, full_name, photo", "placement_score, status", "user_id FK (حسابه الخاص)"], "#065F46"),
   ("guardians أولياء الأمور", ["full_name, phone, relation", "student_guardians (M:N)"], "#065F46"),
   ("teachers المدرسون ⭐", ["max_group_size (سعة المجموعة)", "payroll_type, rate_amount", "teacher_subjects, teacher_availability"], "#065F46"),
   ("employees الموظفون", ["job_title, base_salary", "attendance + leaves + payouts"], "#065F46"),
 ]),
 ("3️⃣ الأكاديمي والدورات", [
   ("subjects المواد", ["id, name_ar/en, color"], "#7C2D12"),
   ("levels + academic_terms", ["مستويات وفصول دراسية"], "#7C2D12"),
   ("course_templates قوالب الدورات ⭐", ["form: كورس/خصوصي/أونلاين/هجين", "default_sessions, base_price", "session_price (للخصوصي)"], "#7C2D12"),
 ]),
 ("4️⃣ المجموعات والجلسات ⭐", [
   ("groups المجموعات ⭐", ["teacher_id, room_id, period", "capacity, sessions_count", "online_link, status"], "#1D4ED8"),
   ("group_schedules الجدول", ["day_of_week, start/end_time"], "#1D4ED8"),
   ("sessions الجلسات ⭐", ["date, seq_no, status", "teacher_id + إحلال تلقائي", "teacher_cost (الاستحقاق)"], "#1D4ED8"),
   ("bookings حجوزات الخصوصي", ["student×teacher×موعد", "price, status (موافقة)"], "#1D4ED8"),
 ]),
 ("5️⃣ التسجيل وقوائم الانتظار ⭐⭐", [
   ("registration_requests طلب التسجيل", ["subject + teacher + period", "pending → approved (الإدارة)"], "#86198F"),
   ("waiting_lists قائمة الانتظار ⭐", ["لكل teacher×subject×period", "priority, offered, expires_at"], "#86198F"),
   ("enrollments التسجيل ⭐", ["student×group UNIQUE", "agreed_price (بعد الحسم)"], "#86198F"),
   ("online_enrollments أونلاين", ["progress_pct, expires_at"], "#86198F"),
 ]),
 ("6️⃣ العمليات التعليمية", [
   ("attendance الحضور ⭐", ["session×student UNIQUE", "present/absent/late/excused", "method: manual/qr/card/link"], "#A16207"),
   ("exams + grades الاختبارات", ["date (تحددها الإدارة), weight", "score, feedback لكل طالب"], "#A16207"),
   ("certificates الشهادات", ["serial_code (رقم تحقق)"], "#A16207"),
 ]),
 ("7️⃣ المالية والمحاسبة ⭐⭐", [
   ("invoices + installments", ["فواتير وأقساط مجدولة", "status: unpaid/partial/paid"], "#9F1239"),
   ("payments المدفوعات", ["cash/card/gateway + مرجع"], "#9F1239"),
   ("discounts الحسم ⭐", ["scope: course/group/student", "pct% + مدة أو عدد جلسات", "granted_by (صلاحية موثقة)"], "#9F1239"),
   ("payouts المستخلصات ⭐", ["teacher_payouts (استحقاق الجلسات)", "employee_payouts (رواتب)"], "#9F1239"),
   ("expenses الصرفيات ⭐", ["category, beneficiary, receipt", "Views: حساب المادة/الطالب/المعلم"], "#9F1239"),
 ]),
 ("8️⃣ المساند والذكاء", [
   ("inventory_items المخزون", ["qty_in_stock, min_qty (تنبيه)", "subject_id → حساب المادة"], "#374151"),
   ("inventory_movements", ["in/out/damaged/lost"], "#374151"),
   ("notifications الإشعارات", ["push/whatsapp/sms/email", "10+ أنواع أحداث"], "#374151"),
   ("ai_predictions الإنذار المبكر", ["risk_score + توصية علاجية"], "#374151"),
 ]),
]

# ---- حساب الارتفاعات التلقائية ----
panel_geo = []  # (title, entities, w, h)
for title, ents in domains:
    h = 34 + 12 + sum(26 + len(f)*16 + 8 + 10 for _, f, _ in ents) + 6
    panel_geo.append((title, ents, h))

COLS = 4
PANEL_W = 480
rows = [panel_geo[:COLS], panel_geo[COLS:]]
row_h = [max(h for _,_,h in r) for r in rows]
W = GAP + COLS * (PANEL_W + GAP) + GAP - GAP
H = HEAD_H + sum(row_h) + GAP*3 + 40

positions = {}
y = HEAD_H
for ri, row in enumerate(rows):
    yy = y
    for ci, (title, ents, h) in enumerate(row):
        x = GAP + ci * (PANEL_W + GAP)
        positions[(ri, ci)] = (x, yy)
    y += row_h[ri] + GAP

def esc(s): return html.escape(s)

parts = []
parts.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}" font-family="{FONT}">')
parts.append('<defs>'
   f'<marker id="arr" markerWidth="9" markerHeight="9" refX="8" refY="4.5" orient="auto"><path d="M0,0 L9,4.5 L0,9 z" fill="{EDGE}"/></marker>'
   f'<marker id="arrA" markerWidth="10" markerHeight="10" refX="9" refY="5" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="{ACCENT}"/></marker>'
   '</defs>')
parts.append(f'<rect width="{W}" height="{H}" fill="#F8FAFC"/>')
parts.append(f'<rect x="0" y="0" width="{W}" height="{HEAD_H-24}" fill="#0F172A"/>')
parts.append(f'<text x="{W/2}" y="40" text-anchor="middle" font-size="25" font-weight="bold" fill="#FFFFFF">مخطط علاقات الكيانات ERD — نظام إدارة المعاهد الذكي v1.0</text>')
parts.append(f'<text x="{W/2}" y="66" text-anchor="middle" font-size="13" fill="#94A3B8">PostgreSQL · بنية Multi-Tenant بعزل institute_id · 40+ كائنًا يطابق الوثيقة المرجعية الشاملة و schema.sql</text>')

E = {}  # anchors

for di, (title, ents, ph) in enumerate(panel_geo):
    ri, ci = di // COLS, di % COLS
    px, py = positions[(ri, ci)]
    parts.append(f'<rect x="{px}" y="{py}" width="{PANEL_W}" height="{ph}" rx="14" fill="#FFFFFF" stroke="#E2E8F0" stroke-width="1.5"/>')
    parts.append(f'<rect x="{px}" y="{py}" width="{PANEL_W}" height="34" rx="14" fill="#0F172A"/>')
    parts.append(f'<rect x="{px}" y="{py+17}" width="{PANEL_W}" height="17" fill="#0F172A"/>')
    parts.append(f'<text x="{px+PANEL_W/2}" y="{py+23}" text-anchor="middle" font-size="14.5" font-weight="bold" fill="#E2E8F0">{esc(title)}</text>')
    cy = py + 46
    bx, bw = px + 15, PANEL_W - 30
    for (name, fields, hcolor) in ents:
        bh = 26 + len(fields)*16 + 8
        parts.append(f'<rect x="{bx}" y="{cy}" width="{bw}" height="{bh}" rx="8" fill="#F1F5F9" stroke="#CBD5E1"/>')
        parts.append(f'<rect x="{bx}" y="{cy}" width="{bw}" height="26" rx="8" fill="{hcolor}"/>')
        parts.append(f'<rect x="{bx}" y="{cy+13}" width="{bw}" height="13" fill="{hcolor}"/>')
        parts.append(f'<text x="{bx+bw/2}" y="{cy+18}" text-anchor="middle" font-size="12.5" font-weight="bold" fill="#FFFFFF">{esc(name)}</text>')
        fy = cy + 26 + 12
        for f in fields:
            parts.append(f'<text x="{bx+bw-10}" y="{fy}" text-anchor="end" font-size="10.5" fill="#334155" style="direction:rtl;unicode-bidi:plaintext">{esc(f)}</text>')
            fy += 16
        key = name.split(' ')[0]
        E[key] = dict(L=(bx, cy+bh/2), R=(bx+bw, cy+bh/2), T=(bx+bw/2, cy), B=(bx+bw/2, cy+bh))
        cy += bh + 10

# العلاقات المنسّقة (من, إلى, تسمية, ذهبي؟, جانب_من, جانب_إلى)
edges = [
 ("registration_requests","waiting_lists","اكتمال المجموعة ← انتظار",True,"B","T"),
 ("waiting_lists","enrollments","فتح مقعد ← تسجيل",True,"B","T"),
 ("groups","sessions","تولّد جلساتها",True,"B","T"),
 ("sessions","attendance","تُسجَّل فيها",True,"L","L"),
 ("enrollments","attendance","طلاب المجموعة",True,"L","R"),
 ("bookings","sessions","ترتبط بجلسة",False,"B","T"),
 ("institutes","branches","1:N",False,"B","T"),
 ("branches","rooms","1:N",False,"R","L"),
 ("institutes","users","1:N",False,"R","R"),
 ("subjects","course_templates","1:N",False,"B","T"),
 ("course_templates","groups","1:N",False,"B","T"),
 ("teachers","groups","يدير 1:N",False,"B","T"),
 ("groups","group_schedules","1:N",False,"B","T"),
 ("teachers","sessions","1:N + إحلال",False,"B","T"),
 ("students","registration_requests","يطلب",False,"R","L"),
 ("students","enrollments","يسجّل",False,"B","T"),
 ("enrollments","invoices","تصدر فاتورة",False,"B","T"),
 ("invoices","installments","1:N",False,"R","L"),
 ("payments","invoices","تسدّد",False,"B","T"),
 ("discounts","enrollments","تحدد السعر",False,"L","R"),
 ("sessions","payouts","تُرحَّل للاستحقاق",False,"B","T"),
 ("exams","certificates","درجات → شهادة",False,"B","T"),
 ("inventory_items","inventory_movements","1:N",False,"B","T"),
 ("ai_predictions","students","تنبؤ عن طالب",False,"R","L"),
]

def bez_label(x1,y1,x2,y2):
    mx = (x1+x2)/2
    # نقطة منتصف منحنى بييزي t=0.5
    lx = (x1 + 3*mx + 3*mx + x2)/8
    ly = (y1 + 3*y1 + 3*y2 + y2)/8
    return lx, ly

for (a, b, label, gold, sa, sb) in edges:
    if a not in E or b not in E: continue
    x1,y1 = E[a][sa]; x2,y2 = E[b][sb]
    color = ACCENT if gold else EDGE
    marker = "arrA" if gold else "arr"
    width = 2.4 if gold else 1.3
    mx = (x1+x2)/2
    parts.append(f'<path d="M{x1},{y1} C{mx},{y1} {mx},{y2} {x2},{y2}" fill="none" stroke="{color}" stroke-width="{width}" marker-end="url(#{marker})" opacity="0.92"/>')
    lx, ly = bez_label(x1,y1,x2,y2)
    wlab = len(label)*6.4 + 10
    parts.append(f'<rect x="{lx-wlab/2}" y="{ly-9}" width="{wlab}" height="16" rx="5" fill="#FFFFFF" stroke="{color}" stroke-width="0.7" opacity="0.96"/>')
    parts.append(f'<text x="{lx}" y="{ly+3}" text-anchor="middle" font-size="10" fill="{color}" style="direction:rtl;unicode-bidi:plaintext">{esc(label)}</text>')

# مفتاح
ly0 = H - 34
parts.append(f'<rect x="{GAP}" y="{ly0-16}" width="470" height="30" rx="8" fill="#FFFFFF" stroke="#E2E8F0"/>')
parts.append(f'<line x1="{GAP+14}" y1="{ly0-1}" x2="{GAP+58}" y2="{ly0-1}" stroke="{ACCENT}" stroke-width="2.5" marker-end="url(#arrA)"/>')
parts.append(f'<text x="{GAP+66}" y="{ly0+3}" font-size="11.5" fill="#0F172A">التدفق الذهبي: الاختيار الحر ← الانتظار ← التسجيل ← الحضور</text>')
parts.append(f'<line x1="{GAP+330}" y1="{ly0-1}" x2="{GAP+372}" y2="{ly0-1}" stroke="{EDGE}" stroke-width="1.4" marker-end="url(#arr)"/>')
parts.append(f'<text x="{GAP+378}" y="{ly0+3}" font-size="11" fill="#334155">علاقة 1:N</text>')

parts.append('</svg>')
svg = "\n".join(parts)
open("/home/user/database/ERD.svg","w",encoding="utf-8").write(svg)
print("OK", len(svg), "bytes,", f"{W}x{H}")

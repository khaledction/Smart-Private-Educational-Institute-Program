-- =====================================================================
--  نظام إدارة المعاهد التعليمية الذكي — مخطط قاعدة البيانات الكامل v1.0
--  Database Schema: Smart Institute Management System (SIMS)
--  المحرك: PostgreSQL 14+   |   البنية: Multi-Tenant (عزل لكل معهد)
--  القاعدة الذهبية: كل جدول تشغيلي يحمل institute_id لعزل بيانات المعاهد
-- =====================================================================

-- =====================================================
-- 0) أنواع مساعدة (ENUM TYPES)
-- =====================================================
CREATE TYPE user_role AS ENUM ('owner','branch_manager','academic_coordinator','accountant','receptionist','teacher','student','guardian');
CREATE TYPE period_type AS ENUM ('morning','evening');            -- الفترات: صباحية / مسائية
CREATE TYPE course_form AS ENUM ('full_course','private_lesson','online_recorded','hybrid'); -- كورس كامل/حصة مستقلة/أونلاين مسجلة/هجين
CREATE TYPE student_status AS ENUM ('lead','trial','active','waiting','paused','withdrawn','graduated');
CREATE TYPE request_status AS ENUM ('pending','approved','rejected','modified');
CREATE TYPE session_status AS ENUM ('scheduled','done','cancelled','postponed','substituted');
CREATE TYPE attendance_status AS ENUM ('present','absent','late','excused');
CREATE TYPE attendance_method AS ENUM ('manual','qr','card','link','biometric');
CREATE TYPE payment_method AS ENUM ('cash','card','transfer','ewallet','gateway');
CREATE TYPE payment_status AS ENUM ('unpaid','partial','paid','refunded');
CREATE TYPE discount_scope AS ENUM ('course','group','student');   -- نطاق الحسم
CREATE TYPE discount_duration_type AS ENUM ('forever','date_range','session_count'); -- مدة الحسم
CREATE TYPE payroll_type AS ENUM ('fixed','per_session','commission');
CREATE TYPE movement_type AS ENUM ('in','out','damaged','lost','adjustment');
CREATE TYPE exam_type AS ENUM ('quiz','midterm','final','placement','oral');
CREATE TYPE notification_channel AS ENUM ('push','whatsapp','sms','email','in_app');

-- =====================================================
-- 1) نواة تعدد المستأجرين (المعاهد والفروع)
-- =====================================================
CREATE TABLE institutes (                       -- المعهد المشترك (Tenant)
    id              BIGSERIAL PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    slug            VARCHAR(80) UNIQUE NOT NULL,          -- subdomain: {slug}.platform.com
    logo_url        TEXT,
    primary_color   VARCHAR(9) DEFAULT '#0EA5E9',          -- تخصيص الهوية البصرية
    default_lang    VARCHAR(2) DEFAULT 'ar',
    currency        VARCHAR(6) DEFAULT 'USD',
    timezone        VARCHAR(50) DEFAULT 'Asia/Damascus',
    plan            VARCHAR(20) DEFAULT 'basic',           -- basic/pro/enterprise
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE branches (                          -- الفروع
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name          VARCHAR(120) NOT NULL,
    address       TEXT,
    phone         VARCHAR(30),
    is_active     BOOLEAN DEFAULT TRUE
);

CREATE TABLE rooms (                             -- القاعات (موارد الجدولة)
    id            BIGSERIAL PRIMARY KEY,
    branch_id     BIGINT NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
    name          VARCHAR(80) NOT NULL,
    capacity      SMALLINT NOT NULL DEFAULT 10,
    equipment     JSONB DEFAULT '[]',                      -- مشروعور، سبورة، أجهزة...
    is_active     BOOLEAN DEFAULT TRUE
);

-- =====================================================
-- 2) المستخدمون والأدوار والصلاحيات (RBAC) + سجل التدقيق
-- =====================================================
CREATE TABLE users (
    id             BIGSERIAL PRIMARY KEY,
    institute_id   BIGINT REFERENCES institutes(id),
    full_name      VARCHAR(150) NOT NULL,
    phone          VARCHAR(30) UNIQUE,
    email          VARCHAR(120) UNIQUE,
    password_hash  TEXT NOT NULL,
    role           user_role NOT NULL,
    lang           VARCHAR(2) DEFAULT 'ar',
    is_active      BOOLEAN DEFAULT TRUE,
    last_login_at  TIMESTAMPTZ,
    created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE permissions (
    id       SERIAL PRIMARY KEY,
    code     VARCHAR(80) UNIQUE NOT NULL,     -- مثال: discounts.grant.up_to_20
    title_ar VARCHAR(120) NOT NULL
);

CREATE TABLE role_permissions (
    role          user_role NOT NULL,
    permission_id INT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role, permission_id)
);

CREATE TABLE audit_logs (                        -- سجل التدقيق: من فعل ماذا ومتى
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    user_id       BIGINT REFERENCES users(id),
    action        VARCHAR(120) NOT NULL,          -- discount.grant / group.create / refund...
    entity_type   VARCHAR(60),
    entity_id     BIGINT,
    details       JSONB,
    ip_address    INET,
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_audit_inst_time ON audit_logs(institute_id, created_at DESC);

-- =====================================================
-- 3) الهيكل الأكاديمي
-- =====================================================
CREATE TABLE subjects (                          -- المواد
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name_ar       VARCHAR(120) NOT NULL,
    name_en       VARCHAR(120),
    color         VARCHAR(9),                              -- لون مميز في الواجهة
    description   TEXT,
    is_active     BOOLEAN DEFAULT TRUE
);

CREATE TABLE levels (                            -- المستويات
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name_ar       VARCHAR(80) NOT NULL,
    sequence      SMALLINT NOT NULL DEFAULT 1
);

CREATE TABLE academic_terms (                    -- الأعوام والفصول
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name          VARCHAR(80) NOT NULL,
    start_date    DATE NOT NULL,
    end_date      DATE NOT NULL,
    is_current    BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- 4) الطلاب وأولياء الأمور
-- =====================================================
CREATE TABLE guardians (                         -- ولي الأمر
    id           BIGSERIAL PRIMARY KEY,
    institute_id BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    full_name    VARCHAR(150) NOT NULL,
    phone        VARCHAR(30) NOT NULL,
    whatsapp     VARCHAR(30),
    relation     VARCHAR(30),                       -- صلة القرابة
    user_id      BIGINT UNIQUE REFERENCES users(id)
);

CREATE TABLE students (                          -- سجل الطالب الشامل
    id                 BIGSERIAL PRIMARY KEY,
    institute_id       BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    code               VARCHAR(30) UNIQUE NOT NULL,          -- رقم الطالب
    full_name          VARCHAR(150) NOT NULL,
    photo_url          TEXT,
    birth_date         DATE,
    nationality        VARCHAR(60),
    id_number          VARCHAR(40),                          -- هوية/جواز
    address            TEXT,
    phone              VARCHAR(30),
    whatsapp           VARCHAR(30),
    email              VARCHAR(120),
    school_name        VARCHAR(150),                         -- المدرسة الأصلية
    placement_score    NUMERIC(5,2),                         -- نتيجة اختبار التحديد
    status             student_status DEFAULT 'lead',
    user_id            BIGINT UNIQUE REFERENCES users(id),
    created_at         TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_students_inst_status ON students(institute_id, status);

CREATE TABLE student_guardians (                 -- ربط الطالب بولي الأمر (أكثر من ولي)
    student_id  BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    guardian_id BIGINT NOT NULL REFERENCES guardians(id) ON DELETE CASCADE,
    is_primary  BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (student_id, guardian_id)
);

-- =====================================================
-- 5) المدرسون
-- =====================================================
CREATE TABLE teachers (
    id              BIGSERIAL PRIMARY KEY,
    institute_id    BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    code            VARCHAR(30) UNIQUE NOT NULL,
    full_name       VARCHAR(150) NOT NULL,
    photo_url       TEXT,
    phone           VARCHAR(30) NOT NULL,
    whatsapp        VARCHAR(30),
    email           VARCHAR(120),
    cv_url          TEXT,                                 -- السيرة الذاتية
    qualifications  TEXT,                                 -- الشهادات والمؤهلات
    experience_years SMALLINT DEFAULT 0,
    max_group_size  SMALLINT NOT NULL DEFAULT 12,         -- سعة المجموعة (يفعّل قائمة الانتظار)
    payroll_type    payroll_type NOT NULL DEFAULT 'per_session',
    rate_amount     NUMERIC(10,2) DEFAULT 0,              -- قيمة الجلسة/النسبة للمدرس
    user_id         BIGINT UNIQUE REFERENCES users(id),
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE teacher_subjects (                  -- المواد المؤهل للتدريس بها
    teacher_id BIGINT NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    subject_id BIGINT NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    PRIMARY KEY (teacher_id, subject_id)
);

CREATE TABLE teacher_availability (              -- التوفر الزمني (صباحي/مسائي)
    id          BIGSERIAL PRIMARY KEY,
    teacher_id  BIGINT NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=الأحد
    period      period_type NOT NULL,
    start_time  TIME,
    end_time    TIME,
    UNIQUE (teacher_id, day_of_week, period)
);

-- =====================================================
-- 6) الموظفون (غير المعلمين)
-- =====================================================
CREATE TABLE employees (
    id             BIGSERIAL PRIMARY KEY,
    institute_id   BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    branch_id      BIGINT REFERENCES branches(id),
    code           VARCHAR(30) UNIQUE NOT NULL,
    full_name      VARCHAR(150) NOT NULL,
    job_title      VARCHAR(80) NOT NULL,                 -- استقبال/محاسب/منسق...
    department     VARCHAR(80),
    hire_date      DATE NOT NULL,
    contract_type  VARCHAR(30) DEFAULT 'full_time',
    base_salary    NUMERIC(10,2) NOT NULL DEFAULT 0,
    phone          VARCHAR(30),
    user_id        BIGINT UNIQUE REFERENCES users(id),
    is_active      BOOLEAN DEFAULT TRUE
);

CREATE TABLE employee_attendance (               -- حضور وانصراف الموظف
    id          BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    date        DATE NOT NULL,
    check_in    TIME,
    check_out   TIME,
    note        TEXT,
    UNIQUE (employee_id, date)
);

CREATE TABLE employee_leaves (                   -- الإجازات (رصيد + موافقة)
    id          BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    leave_type  VARCHAR(30) NOT NULL,                    -- سنوية/مرضية/طارئة
    from_date   DATE NOT NULL,
    to_date     DATE NOT NULL,
    status      request_status DEFAULT 'pending',
    approved_by BIGINT REFERENCES users(id)
);

-- =====================================================
-- 7) الدورات والمجموعات والجلسات (النموذج الهرمي) ⭐
-- =====================================================
CREATE TABLE course_templates (                  -- قالب الدورة
    id             BIGSERIAL PRIMARY KEY,
    institute_id   BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    subject_id     BIGINT NOT NULL REFERENCES subjects(id),
    level_id       BIGINT REFERENCES levels(id),
    name_ar        VARCHAR(150) NOT NULL,
    form           course_form NOT NULL DEFAULT 'full_course',
    default_sessions SMALLINT NOT NULL DEFAULT 12,       -- عدد الحصص الافتراضي
    base_price     NUMERIC(10,2) NOT NULL DEFAULT 0,    -- ثمن الدورة الأساسي
    session_price  NUMERIC(10,2),                       -- أو ثمن الجلسة (للحصص المستقلة)
    session_duration_min SMALLINT DEFAULT 60,
    total_hours    NUMERIC(6,1),
    description    TEXT,
    syllabus_url   TEXT,
    is_active      BOOLEAN DEFAULT TRUE
);

CREATE TABLE groups (                            -- المجموعة (عرض فعلي للقالب) ⭐
    id             BIGSERIAL PRIMARY KEY,
    institute_id   BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    branch_id      BIGINT NOT NULL REFERENCES branches(id),
    course_id      BIGINT NOT NULL REFERENCES course_templates(id),
    teacher_id     BIGINT NOT NULL REFERENCES teachers(id),
    room_id        BIGINT REFERENCES rooms(id),
    name           VARCHAR(120) NOT NULL,                -- "إنجليزي B2 - مسائي أ"
    period         period_type NOT NULL DEFAULT 'evening',
    capacity       SMALLINT NOT NULL,                    -- سعة المجموعة
    sessions_count SMALLINT NOT NULL,                    -- عدد الحصص (تحدده الإدارة)
    start_date     DATE,
    end_date       DATE,
    online_link    TEXT,                                 -- رابط البث (هجين/أونلاين)
    status         VARCHAR(20) DEFAULT 'open',           -- open/running/completed/cancelled
    created_by     BIGINT REFERENCES users(id),
    created_at     TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_groups_inst_status ON groups(institute_id, status);

CREATE TABLE group_schedules (                   -- الجدول الأسبوعي النمطي
    id         BIGSERIAL PRIMARY KEY,
    group_id   BIGINT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
    day_of_week SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time TIME NOT NULL,
    end_time   TIME NOT NULL
);

CREATE TABLE sessions (                          -- الجلسات الفعلية ⭐
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    group_id      BIGINT REFERENCES groups(id) ON DELETE CASCADE,   -- NULL للحصص المستقلة
    seq_no        SMALLINT,                              -- رقم الجلسة داخل الكورس
    date          DATE NOT NULL,
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL,
    room_id       BIGINT REFERENCES rooms(id),
    teacher_id    BIGINT NOT NULL REFERENCES teachers(id), -- يدعم الإحلال
    original_teacher_id BIGINT REFERENCES teachers(id),
    substitution_note TEXT,
    status        session_status DEFAULT 'scheduled',
    topic         TEXT,                                  -- محتوى الجلسة
    teacher_cost  NUMERIC(10,2) DEFAULT 0,               -- استحقاق المدرس لهذه الجلسة
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_sessions_group ON sessions(group_id, date);
CREATE INDEX idx_sessions_teacher_date ON sessions(teacher_id, date, start_time);

CREATE TABLE bookings (                          -- حجوزات الحصص المستقلة/الخصوصي
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    student_id    BIGINT NOT NULL REFERENCES students(id),
    teacher_id    BIGINT NOT NULL REFERENCES teachers(id),
    subject_id    BIGINT NOT NULL REFERENCES subjects(id),
    session_id    BIGINT REFERENCES sessions(id),
    date          DATE NOT NULL,
    start_time    TIME NOT NULL,
    end_time      TIME NOT NULL,
    room_id       BIGINT REFERENCES rooms(id),
    online_link   TEXT,
    status        request_status DEFAULT 'pending',      -- موافقة المدرس/الإدارة
    price         NUMERIC(10,2) DEFAULT 0,               -- ثمن الجلسة للطالب (بعد الحسم)
    cancel_reason TEXT,
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- 8) طلبات التسجيل وقوائم الانتظار ⭐⭐ (قلب نظام الاختيار الحر)
-- =====================================================
CREATE TABLE registration_requests (             -- طلب الطالب: مادة + مدرس + فترة
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    student_id    BIGINT NOT NULL REFERENCES students(id),
    subject_id    BIGINT NOT NULL REFERENCES subjects(id),
    teacher_id    BIGINT REFERENCES teachers(id),        -- المدرس المفضل
    period        period_type NOT NULL,                  -- الفترة المفضلة (صباحي/مسائي)
    preferred_days SMALLINT[],                           -- أيام مفضلة (اختياري)
    target_group_id BIGINT REFERENCES groups(id),        -- المجموعة المقترحة عليه
    status        request_status DEFAULT 'pending',
    decision_note TEXT,                                  -- ملاحظة الإدارة عند الاعتماد/الرفض
    decided_by    BIGINT REFERENCES users(id),
    decided_at    TIMESTAMPTZ,
    created_at    TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_regreq_inst_status ON registration_requests(institute_id, status);

CREATE TABLE waiting_lists (                     -- قائمة انتظار لكل مدرس ⭐
    id           BIGSERIAL PRIMARY KEY,
    institute_id BIGINT NOT NULL,
    student_id   BIGINT NOT NULL REFERENCES students(id),
    teacher_id   BIGINT NOT NULL REFERENCES teachers(id),  -- قائمة انتظار هذا المدرس
    subject_id   BIGINT NOT NULL REFERENCES subjects(id),
    period       period_type NOT NULL,
    priority     INT DEFAULT 0,                          -- أولوية (ترتيب الوصول)
    status       VARCHAR(20) DEFAULT 'waiting',          -- waiting/offered/enrolled/cancelled
    offered_group_id BIGINT REFERENCES groups(id),
    offered_at   TIMESTAMPTZ,                            -- متى عرض عليه مقعد
    expires_at   TIMESTAMPTZ,                            -- مهلة قبول العرض
    created_at   TIMESTAMPTZ DEFAULT now(),
    UNIQUE (student_id, teacher_id, subject_id, period)
);

CREATE TABLE enrollments (                       -- التسجيل الفعلي: طالب × مجموعة ⭐
    id              BIGSERIAL PRIMARY KEY,
    institute_id    BIGINT NOT NULL,
    student_id      BIGINT NOT NULL REFERENCES students(id),
    group_id        BIGINT NOT NULL REFERENCES groups(id),
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    agreed_price    NUMERIC(10,2) NOT NULL,              -- الثمن النهائي بعد الحسم
    status          VARCHAR(20) DEFAULT 'active',        -- active/completed/withdrawn/transferred
    attended_sessions INT DEFAULT 0,
    UNIQUE (student_id, group_id)
);

CREATE TABLE online_enrollments (                -- اشتراك الدورات المسجلة (Self-paced)
    id           BIGSERIAL PRIMARY KEY,
    institute_id BIGINT NOT NULL,
    student_id   BIGINT NOT NULL REFERENCES students(id),
    course_id    BIGINT NOT NULL REFERENCES course_templates(id),
    starts_at    TIMESTAMPTZ DEFAULT now(),
    expires_at   TIMESTAMPTZ,                            -- مدة صلاحية الاشتراك
    progress_pct NUMERIC(5,2) DEFAULT 0,
    status       VARCHAR(20) DEFAULT 'active'
);

-- =====================================================
-- 9) الحضور والغياب (لكل مجموعة على حدة)
-- =====================================================
CREATE TABLE attendance (
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    session_id    BIGINT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    student_id    BIGINT NOT NULL REFERENCES students(id),
    status        attendance_status NOT NULL DEFAULT 'present',
    method        attendance_method DEFAULT 'manual',
    recorded_by   BIGINT REFERENCES users(id),
    recorded_at   TIMESTAMPTZ DEFAULT now(),
    UNIQUE (session_id, student_id)
);
CREATE INDEX idx_attendance_student ON attendance(student_id);

-- =====================================================
-- 10) الاختبارات والتقييم والشهادات
-- =====================================================
CREATE TABLE exams (
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    group_id      BIGINT REFERENCES groups(id),
    student_id    BIGINT REFERENCES students(id),        -- اختبار فردي (تحديد مستوى)
    course_id     BIGINT REFERENCES course_templates(id),
    type          exam_type NOT NULL,
    title         VARCHAR(150) NOT NULL,
    date          DATE NOT NULL,                         -- الموعد (تحدده الإدارة)
    start_time    TIME,
    max_score     NUMERIC(5,2) DEFAULT 100,
    weight_pct    NUMERIC(5,2) DEFAULT 0,                -- وزنه في التقييم النهائي
    created_by    BIGINT REFERENCES users(id)
);

CREATE TABLE grades (
    id         BIGSERIAL PRIMARY KEY,
    exam_id    BIGINT NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES students(id),
    score      NUMERIC(5,2),
    feedback   TEXT,                                     -- تغذية راجعة للطالب
    graded_by  BIGINT REFERENCES users(id),
    graded_at  TIMESTAMPTZ,
    UNIQUE (exam_id, student_id)
);

CREATE TABLE certificates (
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    student_id    BIGINT NOT NULL REFERENCES students(id),
    course_id     BIGINT REFERENCES course_templates(id),
    group_id      BIGINT REFERENCES groups(id),
    serial_code   VARCHAR(40) UNIQUE NOT NULL,           -- رقم التحقق
    final_score   NUMERIC(5,2),
    issued_at     TIMESTAMPTZ DEFAULT now(),
    pdf_url       TEXT
);

-- =====================================================
-- 11) المالية: الأقساط والمدفوعات والفواتير والحسم ⭐⭐
-- =====================================================
CREATE TABLE invoices (
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    student_id    BIGINT NOT NULL REFERENCES students(id),
    enrollment_id BIGINT REFERENCES enrollments(id),
    booking_id    BIGINT REFERENCES bookings(id),
    number        VARCHAR(40) NOT NULL,
    issue_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount  NUMERIC(10,2) NOT NULL DEFAULT 0,
    discount_amount NUMERIC(10,2) DEFAULT 0,
    tax_amount    NUMERIC(10,2) DEFAULT 0,
    net_amount    NUMERIC(10,2) NOT NULL DEFAULT 0,
    status        payment_status DEFAULT 'unpaid',
    notes         TEXT
);

CREATE TABLE installments (                      -- جدولة الأقساط
    id           BIGSERIAL PRIMARY KEY,
    invoice_id   BIGINT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    seq_no       SMALLINT NOT NULL,
    due_date     DATE NOT NULL,
    amount       NUMERIC(10,2) NOT NULL,
    status       payment_status DEFAULT 'unpaid',
    UNIQUE (invoice_id, seq_no)
);

CREATE TABLE payments (
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    invoice_id    BIGINT REFERENCES invoices(id),
    installment_id BIGINT REFERENCES installments(id),
    student_id    BIGINT NOT NULL REFERENCES students(id),
    amount        NUMERIC(10,2) NOT NULL,
    method        payment_method NOT NULL,
    reference     VARCHAR(80),                           -- رقم عملية البوابة
    received_by   BIGINT REFERENCES users(id),
    paid_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE discounts (                         -- نظام الحسم المرن ⭐
    id              BIGSERIAL PRIMARY KEY,
    institute_id    BIGINT NOT NULL,
    name            VARCHAR(120) NOT NULL,
    scope           discount_scope NOT NULL,             -- دورة كاملة/مجموعة/طالب
    course_id       BIGINT REFERENCES course_templates(id),  -- لنطاق course
    group_id        BIGINT REFERENCES groups(id),            -- لنطاق group
    student_id      BIGINT REFERENCES students(id),          -- لنطاق student
    pct             NUMERIC(5,2) NOT NULL CHECK (pct BETWEEN 0 AND 100),  -- نسبة الحسم
    duration_type   discount_duration_type NOT NULL DEFAULT 'forever',
    valid_from      DATE,
    valid_to        DATE,                                -- مدة الحسم الزمنية
    session_count   SMALLINT,                            -- أو عدد الجلسات/المواد المشمولة
    is_active       BOOLEAN DEFAULT TRUE,
    granted_by      BIGINT NOT NULL REFERENCES users(id),-- من منح الحسم (صلاحية)
    reason          TEXT,
    created_at      TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT discount_target_chk CHECK (
        (scope='course' AND course_id IS NOT NULL) OR
        (scope='group'  AND group_id  IS NOT NULL) OR
        (scope='student' AND student_id IS NOT NULL)
    )
);

-- =====================================================
-- 12) رواتب المعلمين والموظفين والصرفيات ⭐
-- =====================================================
CREATE TABLE teacher_payouts (                   -- مستخلصات المعلمين
    id           BIGSERIAL PRIMARY KEY,
    institute_id BIGINT NOT NULL,
    teacher_id   BIGINT NOT NULL REFERENCES teachers(id),
    period_start DATE NOT NULL,
    period_end   DATE NOT NULL,
    sessions_count INT NOT NULL DEFAULT 0,
    gross_amount NUMERIC(10,2) NOT NULL DEFAULT 0,       -- إجمالي الاستحقاق
    deductions   NUMERIC(10,2) DEFAULT 0,                -- خصومات/سلف
    net_amount   NUMERIC(10,2) NOT NULL DEFAULT 0,
    status       VARCHAR(20) DEFAULT 'pending',
    paid_at      TIMESTAMPTZ
);

CREATE TABLE employee_payouts (                  -- رواتب الموظفين
    id           BIGSERIAL PRIMARY KEY,
    institute_id BIGINT NOT NULL,
    employee_id  BIGINT NOT NULL REFERENCES employees(id),
    period_start DATE NOT NULL,
    period_end   DATE NOT NULL,
    base_salary  NUMERIC(10,2) NOT NULL DEFAULT 0,
    allowances   NUMERIC(10,2) DEFAULT 0,                -- بدلات
    deductions   NUMERIC(10,2) DEFAULT 0,                -- خصومات
    net_amount   NUMERIC(10,2) NOT NULL DEFAULT 0,
    status       VARCHAR(20) DEFAULT 'pending',
    paid_at      TIMESTAMPTZ
);

CREATE TABLE expense_categories (                -- تصنيف الصرفيات
    id           SERIAL PRIMARY KEY,
    institute_id BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    name_ar      VARCHAR(100) NOT NULL                   -- إيجار/فواتير/نثريات/مواصلات...
);

CREATE TABLE expenses (                          -- الصرفيات (المصروفات) ⭐
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL,
    branch_id     BIGINT REFERENCES branches(id),
    category_id   BIGINT REFERENCES expense_categories(id),
    amount        NUMERIC(10,2) NOT NULL,
    spent_at      DATE NOT NULL DEFAULT CURRENT_DATE,
    beneficiary   VARCHAR(150),                          -- من استلم/من أُدفع له
    description   TEXT,
    receipt_url   TEXT,
    created_by    BIGINT REFERENCES users(id),
    created_at    TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- 13) المخزون والأصول
-- =====================================================
CREATE TABLE inventory_items (
    id            BIGSERIAL PRIMARY KEY,
    institute_id  BIGINT NOT NULL REFERENCES institutes(id) ON DELETE CASCADE,
    category      VARCHAR(60) NOT NULL,                  -- كتب/ملازم/مكتبية/أجهزة
    name          VARCHAR(120) NOT NULL,
    sku           VARCHAR(40) UNIQUE,
    unit          VARCHAR(20) DEFAULT 'piece',
    qty_in_stock  INT NOT NULL DEFAULT 0,
    min_qty       INT DEFAULT 5,                         -- حد التنبيه
    unit_cost     NUMERIC(10,2) DEFAULT 0,
    is_asset      BOOLEAN DEFAULT FALSE,                 -- أصل مؤمن (أجهزة)
    subject_id    BIGINT REFERENCES subjects(id)         -- ربط ملازم المادة بحسابها
);

CREATE TABLE inventory_movements (
    id          BIGSERIAL PRIMARY KEY,
    institute_id BIGINT NOT NULL,
    item_id     BIGINT NOT NULL REFERENCES inventory_items(id),
    movement    movement_type NOT NULL,
    qty         INT NOT NULL,
    student_id  BIGINT REFERENCES students(id),          -- بيع/تسليم لطالب (يرتبط بفاتورته)
    invoice_id  BIGINT REFERENCES invoices(id),
    handled_by  BIGINT REFERENCES users(id),
    note        TEXT,
    created_at  TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- 14) الإشعارات والتواصل
-- =====================================================
CREATE TABLE notifications (
    id           BIGSERIAL PRIMARY KEY,
    institute_id BIGINT NOT NULL,
    user_id      BIGINT REFERENCES users(id),
    student_id   BIGINT REFERENCES students(id),         -- للإشعارات الموجهة للطالب/ولي الأمر
    channel      notification_channel NOT NULL,
    event_type   VARCHAR(60) NOT NULL,                   -- waiting_list.offer / absence.alert / installment.reminder / stock.low ...
    title        VARCHAR(150),
    body         TEXT,
    payload      JSONB,
    is_read      BOOLEAN DEFAULT FALSE,
    sent_at      TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_notif_student ON notifications(student_id, sent_at DESC);

-- =====================================================
-- 15) طبقة الذكاء الاصطناعي
-- =====================================================
CREATE TABLE ai_predictions (                    -- الإنذار المبكر
    id           BIGSERIAL PRIMARY KEY,
    institute_id BIGINT NOT NULL,
    student_id   BIGINT NOT NULL REFERENCES students(id),
    model        VARCHAR(60) NOT NULL,                   -- dropout_risk / weak_performance
    risk_score   NUMERIC(5,2),                           -- 0-100
    risk_level   VARCHAR(10),                            -- low/medium/high
    reasons      JSONB,                                  -- مبررات التنبؤ (غياب+درجات)
    recommendation TEXT,
    created_at   TIMESTAMPTZ DEFAULT now()
);

-- =====================================================
-- 16) VIEWS جاهزة: المحاسبة لكل كيان ⭐⭐ (متطلبات المشروع الصريحة)
-- =====================================================

-- (أ) حساب كل مادة: إيرادات − تكاليف = صافي الربح
CREATE VIEW v_subject_account AS
SELECT s.id AS subject_id, s.name_ar,
       COALESCE(rev.revenue,0) AS revenue,
       COALESCE(cost.teacher_cost,0) AS teacher_cost,
       COALESCE(rev.revenue,0) - COALESCE(cost.teacher_cost,0) AS net_profit
FROM subjects s
LEFT JOIN (
    SELECT g2.course_id, c.subject_id, SUM(e.agreed_price) AS revenue
    FROM enrollments e JOIN groups g2 ON g2.id=e.group_id
    JOIN course_templates c ON c.id=g2.course_id
    WHERE e.status='active' GROUP BY g2.course_id, c.subject_id
) rev ON rev.subject_id = s.id
LEFT JOIN (
    SELECT c2.subject_id, SUM(s2.teacher_cost) AS teacher_cost
    FROM sessions s2 JOIN groups g3 ON g3.id=s2.group_id
    JOIN course_templates c2 ON c2.id=g3.course_id
    WHERE s2.status='done' GROUP BY c2.subject_id
) cost ON cost.subject_id = s.id;

-- (ب) حساب كل طالب
CREATE VIEW v_student_account AS
SELECT st.id AS student_id, st.code, st.full_name,
       COALESCE(inv.billed,0)  AS total_billed,
       COALESCE(pay.paid,0)    AS total_paid,
       COALESCE(inv.billed,0) - COALESCE(pay.paid,0) AS balance_due
FROM students st
LEFT JOIN (SELECT student_id, SUM(net_amount) AS billed FROM invoices GROUP BY student_id) inv ON inv.student_id=st.id
LEFT JOIN (SELECT student_id, SUM(amount) AS paid FROM payments GROUP BY student_id) pay ON pay.student_id=st.id;

-- (ج) حساب كل معلم
CREATE VIEW v_teacher_account AS
SELECT t.id AS teacher_id, t.full_name,
       COALESCE(earned.amount,0) AS total_earned,
       COALESCE(payout.paid,0)   AS total_paid_out,
       COALESCE(earned.amount,0) - COALESCE(payout.paid,0) AS balance_owed
FROM teachers t
LEFT JOIN (SELECT teacher_id, SUM(teacher_cost) AS amount FROM sessions WHERE status='done' GROUP BY teacher_id) earned ON earned.teacher_id=t.id
LEFT JOIN (SELECT teacher_id, SUM(net_amount) AS paid FROM teacher_payouts WHERE status='paid' GROUP BY teacher_id) payout ON payout.teacher_id=t.id;

-- (د) تقرير نهاية الجلسة
CREATE VIEW v_session_report AS
SELECT ses.id AS session_id, ses.date, g.name AS group_name, t.full_name AS teacher,
       (SELECT count(*) FROM attendance a WHERE a.session_id=ses.id AND a.status='present') AS present_count,
       (SELECT count(*) FROM attendance a WHERE a.session_id=ses.id AND a.status='absent')  AS absent_count,
       ses.teacher_cost,
       ROUND( (SELECT SUM(e.agreed_price) FROM enrollments e WHERE e.group_id=g.id AND e.status='active')
              / GREATEST(g.sessions_count,1) , 2) AS session_revenue
FROM sessions ses
JOIN groups g ON g.id=ses.group_id
JOIN teachers t ON t.id=ses.teacher_id;

-- (هـ) لوحة الدورات: عدد المسجلين لكل دورة ⭐ (شاشة الواجهة العصرية)
CREATE VIEW v_course_dashboard AS
SELECT g.id AS group_id, g.name AS group_name, c.name_ar AS course, s.name_ar AS subject,
       t.full_name AS teacher, g.period, g.capacity,
       (SELECT count(*) FROM enrollments e WHERE e.group_id=g.id AND e.status='active') AS enrolled_count,
       g.capacity - (SELECT count(*) FROM enrollments e WHERE e.group_id=g.id AND e.status='active') AS seats_left,
       (SELECT count(*) FROM waiting_lists w WHERE w.teacher_id=g.teacher_id AND w.subject_id=g.course_id AND w.status='waiting') AS waiting_count
FROM groups g
JOIN course_templates c ON c.id=g.course_id
JOIN subjects s ON s.id=c.subject_id
JOIN teachers t ON t.id=g.teacher_id
WHERE g.status IN ('open','running');

-- (و) إشعار انخفاض المخزون
CREATE VIEW v_low_stock AS
SELECT id, name, qty_in_stock, min_qty FROM inventory_items WHERE qty_in_stock <= min_qty;

-- =====================================================================
-- نهاية المخطط — 40+ كائن (جداول + ENUMs + Views) تغطي كل متطلبات الوثيقة
-- =====================================================================

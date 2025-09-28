// ملف خاص لتخزين المفاتيح الحساسة

// --- ثانياً: نظام قوي للذكاء الاصطناعي ---
// أضف هنا مفاتيح Gemini API الخاصة بك. سيقوم النظام بالمداورة بينها تلقائياً.
const List<String> geminiApiKeys = [
  'AIzaSyAuJFcS6MDbrCDKc6lmo1Q35uvGBhhYOZI', // المفتاح الأول
  'AIzaSyDC2af8Pw1Vb4q2L8WCg5Vhld4aQQtcLIw', // المفتاح الثاني (احتياطي)
  'AIzaSyAcKIsLE3JgERnI9_2HG7tPWAXlS0e_YuM', // المفتاح الثالث (احتياطي)
  // يمكنك إضافة المزيد من المفاتيح هنا
];

// معلومات Supabase لتخزين الملفات (اختياري)
const String supabaseUrl =
    'https://crtcxjyxjcozuwpntyws.supabase.co'; // ضع رابط المشروع هنا
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNydGN4anl4amNvenV3cG50eXdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyODc0NjgsImV4cCI6MjA3MTg2MzQ2OH0.pucDfzbWSf7JR4eT3BD7ybJ-4avSFOoLwpE3qNYz2SA'; // ضع مفتاح anon هنا

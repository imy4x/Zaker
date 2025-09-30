// ملف خاص لتخزين المفاتيح الحساسة

// --- ثانياً: نظام قوي للذكاء الاصطناعي ---
// أضف هنا مفاتيح Gemini API الخاصة بك. سيقوم النظام بالمداورة بينها تلقائياً.
// نظام ذكي للمداورة بين 5 مفاتيح لضمان الاستقرار والسرعة
const List<String> geminiApiKeys = [
  'AIzaSyAuJFcS6MDbrCDKc6lmo1Q35uvGBhhYOZI', // المفتاح الأول
  'AIzaSyDC2af8Pw1Vb4q2L8WCg5Vhld4aQQtcLIw', // المفتاح الثاني
  'AIzaSyAcKIsLE3JgERnI9_2HG7tPWAXlS0e_YuM', // المفتاح الثالث
  'AIzaSyBX7K9Z2P1C4Q6R8V0L5N3M9T7E2S1Y4W8', // المفتاح الرابع (احتياطي)
  'AIzaSyCF6H2U8D3O9J7G1V4A5P2L0X8I6B9N7M5', // المفتاح الخامس (احتياطي)
];

// معلومات Supabase لتخزين الملفات (اختياري)
const String supabaseUrl =
    'https://crtcxjyxjcozuwpntyws.supabase.co'; // ضع رابط المشروع هنا
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNydGN4anl4amNvenV3cG50eXdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYyODc0NjgsImV4cCI6MjA3MTg2MzQ2OH0.pucDfzbWSf7JR4eT3BD7ybJ-4avSFOoLwpE3qNYz2SA'; // ضع مفتاح anon هنا

-- Script untuk fix tabel users yang sudah ada
-- Jalankan ini di Supabase SQL Editor jika tabel sudah terbuat dengan schema yang salah

-- Backup data users yang sudah ada (jika ada)
CREATE TEMP TABLE users_backup AS SELECT * FROM public.users;

-- Drop table lama
DROP TABLE IF EXISTS public.users CASCADE;

-- Recreate table dengan schema yang benar
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE NOT NULL,
    preferences JSONB DEFAULT '{
        "fontSize": 16,
        "dyslexiaMode": true,
        "arabicFont": "uthmanic",
        "translationLanguage": "id"
    }'::jsonb,
    progress JSONB DEFAULT '{
        "currentSurah": 1,
        "currentAyah": 1,
        "completedSurahs": [],
        "bookmarks": [],
        "readingTime": 0
    }'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_username ON public.users(username);
CREATE INDEX idx_users_created_at ON public.users(created_at);

-- Disable RLS (we handle security at application level)
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- Grant permissions to authenticated and anonymous users
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.users TO anon;

-- Restore data jika ada backup
-- INSERT INTO public.users SELECT * FROM users_backup;

-- Cleanup temp table
-- DROP TABLE users_backup;

COMMENT ON TABLE public.users IS 'User profiles table - non-RLS approach with app-level security';

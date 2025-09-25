-- Supabase Database Schema untuk Afdyl Quran App (Non-RLS Version)
-- Jalankan script ini di Supabase SQL Editor

-- Create users table (extends auth.users)
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

-- Create trigger to automatically update updated_at
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Create indexes for better performance
CREATE INDEX idx_users_username ON public.users(username);
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_created_at ON public.users(created_at);

-- Create function to handle new user registration (Optional)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, username)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user registration (Optional)
-- CREATE TRIGGER on_auth_user_created
--     AFTER INSERT ON auth.users
--     FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to check username availability
CREATE OR REPLACE FUNCTION public.check_username_availability(username_input TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN NOT EXISTS (
        SELECT 1 FROM public.users 
        WHERE LOWER(username) = LOWER(username_input)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions to authenticated users (since no RLS)
GRANT ALL ON public.users TO authenticated;
GRANT ALL ON public.users TO anon;

-- Note: RLS is disabled, so all operations will use service role permissions
-- This provides full access but sacrifices row-level security
-- Make sure to handle authorization in your application logic

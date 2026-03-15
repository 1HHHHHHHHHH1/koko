-- ============================================================
--  supabase_schema.sql
--  شغّل هذا الملف كاملاً في Supabase → SQL Editor مرة واحدة
-- ============================================================

-- 1. PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT        NOT NULL,
  name          TEXT        NOT NULL DEFAULT '',
  user_type     TEXT        NOT NULL DEFAULT 'entrepreneur'
                            CHECK (user_type IN ('entrepreneur','investor')),
  avatar        TEXT,
  bio           TEXT,
  company       TEXT,
  position      TEXT,
  location      TEXT,
  website       TEXT,
  linkedin      TEXT,
  industries    TEXT[]      DEFAULT '{}',
  average_rating NUMERIC    DEFAULT 0,
  total_ratings INT         DEFAULT 0,
  total_likes   INT         DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, user_type)
  VALUES (
    NEW.id, NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'user_type', 'entrepreneur')
  ) ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. PROJECTS
CREATE TABLE IF NOT EXISTS public.projects (
  id             UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id       UUID    NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title          TEXT    NOT NULL,
  description    TEXT    NOT NULL DEFAULT '',
  industry       TEXT    NOT NULL,
  stage          TEXT    NOT NULL,
  funding_goal   NUMERIC NOT NULL DEFAULT 0,
  funding_raised NUMERIC DEFAULT 0,
  pitch_deck     TEXT,
  website        TEXT,
  video_url      TEXT,
  team_members   TEXT[]  DEFAULT '{}',
  tags           TEXT[]  DEFAULT '{}',
  average_rating NUMERIC DEFAULT 0,
  total_ratings  INT     DEFAULT 0,
  total_likes    INT     DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- 3. INVESTORS
CREATE TABLE IF NOT EXISTS public.investors (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  portfolio      TEXT[] DEFAULT '{}',
  criteria       JSONB  DEFAULT '{}',
  average_rating NUMERIC DEFAULT 0,
  total_ratings  INT     DEFAULT 0,
  total_likes    INT     DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id)
);

-- 4. MATCHES
CREATE TABLE IF NOT EXISTS public.matches (
  id                UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  entrepreneur_id   UUID    REFERENCES public.profiles(id) ON DELETE CASCADE,
  investor_id       UUID    REFERENCES public.profiles(id) ON DELETE CASCADE,
  target_id         UUID    NOT NULL,
  target_type       TEXT    NOT NULL CHECK (target_type IN ('investor','project')),
  match_percentage  NUMERIC NOT NULL DEFAULT 0,
  matching_criteria TEXT[]  DEFAULT '{}',
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- 5. LIKES
CREATE TABLE IF NOT EXISTS public.likes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  target_id   UUID NOT NULL,
  target_type TEXT NOT NULL CHECK (target_type IN ('investor','entrepreneur','project')),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, target_id, target_type)
);

-- 6. RATINGS
CREATE TABLE IF NOT EXISTS public.ratings (
  id          UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID     NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_name   TEXT     NOT NULL DEFAULT '',
  user_avatar TEXT,
  target_id   UUID     NOT NULL,
  target_type TEXT     NOT NULL CHECK (target_type IN ('investor','entrepreneur','project')),
  score       SMALLINT NOT NULL CHECK (score BETWEEN 1 AND 5),
  comment     TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, target_id, target_type)
);

-- 7. CONVERSATIONS + MESSAGES
CREATE TABLE IF NOT EXISTS public.conversations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.conversation_participants (
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES public.profiles(id)      ON DELETE CASCADE,
  PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
  id              UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID    NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id       UUID    NOT NULL REFERENCES public.profiles(id)      ON DELETE CASCADE,
  content         TEXT    NOT NULL,
  is_read         BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 8. ROW LEVEL SECURITY
ALTER TABLE public.profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.investors     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ratings       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches       ENABLE ROW LEVEL SECURITY;

-- profiles
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (TRUE);
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- projects
DROP POLICY IF EXISTS "projects_select" ON public.projects;
DROP POLICY IF EXISTS "projects_insert" ON public.projects;
DROP POLICY IF EXISTS "projects_update" ON public.projects;
DROP POLICY IF EXISTS "projects_delete" ON public.projects;
CREATE POLICY "projects_select" ON public.projects FOR SELECT USING (TRUE);
CREATE POLICY "projects_insert" ON public.projects FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "projects_update" ON public.projects FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "projects_delete" ON public.projects FOR DELETE USING (auth.uid() = owner_id);

-- investors
DROP POLICY IF EXISTS "investors_select" ON public.investors;
DROP POLICY IF EXISTS "investors_insert" ON public.investors;
DROP POLICY IF EXISTS "investors_update" ON public.investors;
CREATE POLICY "investors_select" ON public.investors FOR SELECT USING (TRUE);
CREATE POLICY "investors_insert" ON public.investors FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "investors_update" ON public.investors FOR UPDATE USING (auth.uid() = user_id);

-- likes
DROP POLICY IF EXISTS "likes_select" ON public.likes;
DROP POLICY IF EXISTS "likes_insert" ON public.likes;
DROP POLICY IF EXISTS "likes_delete" ON public.likes;
CREATE POLICY "likes_select" ON public.likes FOR SELECT USING (TRUE);
CREATE POLICY "likes_insert" ON public.likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "likes_delete" ON public.likes FOR DELETE USING (auth.uid() = user_id);

-- ratings
DROP POLICY IF EXISTS "ratings_select" ON public.ratings;
DROP POLICY IF EXISTS "ratings_insert" ON public.ratings;
CREATE POLICY "ratings_select" ON public.ratings FOR SELECT USING (TRUE);
CREATE POLICY "ratings_insert" ON public.ratings FOR INSERT WITH CHECK (auth.uid() = user_id);

-- matches
DROP POLICY IF EXISTS "matches_select" ON public.matches;
CREATE POLICY "matches_select" ON public.matches FOR SELECT
  USING (auth.uid() = entrepreneur_id OR auth.uid() = investor_id);

-- messages
DROP POLICY IF EXISTS "messages_select" ON public.messages;
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
CREATE POLICY "messages_select" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.conversation_participants cp
    WHERE cp.conversation_id = messages.conversation_id AND cp.user_id = auth.uid())
);
CREATE POLICY "messages_insert" ON public.messages FOR INSERT
  WITH CHECK (auth.uid() = sender_id);

-- conversations
DROP POLICY IF EXISTS "conversations_select" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert" ON public.conversations;
CREATE POLICY "conversations_select" ON public.conversations FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.conversation_participants cp
    WHERE cp.conversation_id = conversations.id AND cp.user_id = auth.uid())
);
CREATE POLICY "conversations_insert" ON public.conversations FOR INSERT WITH CHECK (TRUE);

-- conversation_participants
DROP POLICY IF EXISTS "conv_p_select" ON public.conversation_participants;
DROP POLICY IF EXISTS "conv_p_insert" ON public.conversation_participants;
CREATE POLICY "conv_p_select" ON public.conversation_participants FOR SELECT USING (TRUE);
CREATE POLICY "conv_p_insert" ON public.conversation_participants FOR INSERT WITH CHECK (TRUE);

-- 9. REALTIME
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;

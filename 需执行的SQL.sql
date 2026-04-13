-- 自动创建用户 profile 的触发器
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, nickname, created_at)
  VALUES (NEW.id, NEW.phone, NEW.email, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 删除已存在的触发器（如果有）
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 创建触发器
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 为 houses 表添加 RLS 策略
ALTER TABLE houses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "用户可查看自己的房子" ON houses
  FOR SELECT USING (owner_id = auth.uid());

CREATE POLICY "用户可创建房子" ON houses
  FOR INSERT WITH CHECK (owner_id = auth.uid());

CREATE POLICY "用户可更新自己的房子" ON houses
  FOR UPDATE USING (owner_id = auth.uid());

CREATE POLICY "用户可删除自己的房子" ON houses
  FOR DELETE USING (owner_id = auth.uid());

-- 为 house_members 表添加 RLS 策略
ALTER TABLE house_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "用户可查看房子成员" ON house_members
  FOR SELECT USING (
    house_id IN (SELECT id FROM houses WHERE owner_id = auth.uid())
    OR user_id = auth.uid()
  );

CREATE POLICY "用户可加入房子" ON house_members
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- 为 invite_codes 表添加 RLS 策略
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "用户可查看邀请码" ON invite_codes
  FOR SELECT USING (created_by = auth.uid() OR true);

CREATE POLICY "用户可创建邀请码" ON invite_codes
  FOR INSERT WITH CHECK (created_by = auth.uid());

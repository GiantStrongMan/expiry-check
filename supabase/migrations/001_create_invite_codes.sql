-- 家庭共享邀请码表
-- 用于存储邀请码信息，支持邀请家庭成员加入房子

CREATE TABLE IF NOT EXISTS invite_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    house_id UUID REFERENCES houses(id) ON DELETE CASCADE,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 创建索引以加速查询
CREATE INDEX IF NOT EXISTS idx_invite_codes_code ON invite_codes(code);
CREATE INDEX IF NOT EXISTS idx_invite_codes_house_id ON invite_codes(house_id);
CREATE INDEX IF NOT EXISTS idx_invite_codes_expires_at ON invite_codes(expires_at);

-- 启用行级安全策略
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

-- 允许房子所有者查看和删除自己的邀请码
CREATE POLICY "House owners can view invite codes" ON invite_codes
    FOR SELECT USING (
        house_id IN (
            SELECT id FROM houses WHERE user_id = auth.uid()
        )
    );

CREATE POLICY "House owners can delete invite codes" ON invite_codes
    FOR DELETE USING (
        house_id IN (
            SELECT id FROM houses WHERE user_id = auth.uid()
        )
    );

-- 允许已认证用户创建邀请码
CREATE POLICY "Authenticated users can create invite codes" ON invite_codes
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 清理过期邀请码的函数（可选定时任务）
CREATE OR REPLACE FUNCTION cleanup_expired_invite_codes()
RETURNS void AS $$
BEGIN
    DELETE FROM invite_codes WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 彻底修复 houses、house_members、invite_codes 表的 RLS 策略
-- 请在 Supabase SQL Editor 中执行此脚本
-- 执行时间：2026-04-14
-- =====================================================

-- 1. 删除 houses 表的所有旧策略
DROP POLICY IF EXISTS "用户可查看自己的房子" ON houses;
DROP POLICY IF EXISTS "用户可创建房子" ON houses;
DROP POLICY IF EXISTS "用户可更新自己的房子" ON houses;
DROP POLICY IF EXISTS "用户可删除自己的房子" ON houses;
DROP POLICY IF EXISTS "Allow all users to view houses" ON houses;
DROP POLICY IF EXISTS "Allow all authenticated users to create houses" ON houses;

-- 2. 重新创建 houses 表的 RLS 策略
-- 策略1: 任何已认证用户都可以查看所有房子（用于邀请码验证和列表展示）
CREATE POLICY "所有已认证用户可查看所有房子" ON houses
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- 策略2: 任何已认证用户都可以创建房子
CREATE POLICY "所有已认证用户可创建房子" ON houses
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- 策略3: 只有房主可以更新自己的房子
CREATE POLICY "房主可更新自己的房子" ON houses
    FOR UPDATE
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

-- 策略4: 只有房主可以删除自己的房子
CREATE POLICY "房主可删除自己的房子" ON houses
    FOR DELETE
    USING (owner_id = auth.uid());

-- 3. 删除 house_members 表的所有旧策略
DROP POLICY IF EXISTS "用户可查看房子成员" ON house_members;
DROP POLICY IF EXISTS "用户可加入房子" ON house_members;
DROP POLICY IF EXISTS "Allow all users to view house_members" ON house_members;

-- 4. 重新创建 house_members 表的 RLS 策略
-- 策略1: 房主可以查看所有成员，用户可以查看自己加入的房子的成员和自己的记录
CREATE POLICY "房主和成员可查看房子成员" ON house_members
    FOR SELECT
    USING (
        -- 用户是房主
        house_id IN (SELECT id FROM houses WHERE owner_id = auth.uid())
        -- 或者用户是成员
        OR user_id = auth.uid()
        -- 或者用户是房子的某个成员
        OR house_id IN (SELECT house_id FROM house_members WHERE user_id = auth.uid())
    );

-- 策略2: 任何已认证用户都可以加入房子（通过邀请码）
CREATE POLICY "已认证用户可加入房子" ON house_members
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- 策略3: 用户可以更新自己的成员记录
CREATE POLICY "用户可更新自己的成员记录" ON house_members
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- 策略4: 用户可以删除自己的成员记录（退出房子）
CREATE POLICY "用户可退出房子" ON house_members
    FOR DELETE
    USING (user_id = auth.uid());

-- 5. 删除 invite_codes 表的所有旧策略
DROP POLICY IF EXISTS "House owners can view invite codes" ON invite_codes;
DROP POLICY IF EXISTS "House owners can delete invite codes" ON invite_codes;
DROP POLICY IF EXISTS "Authenticated users can create invite codes" ON invite_codes;
DROP POLICY IF EXISTS "用户可查看邀请码" ON invite_codes;
DROP POLICY IF EXISTS "用户可创建邀请码" ON invite_codes;

-- 6. 重新创建 invite_codes 表的 RLS 策略
-- 策略1: 任何已认证用户都可以查看邀请码（用于输入邀请码加入房子）
CREATE POLICY "已认证用户可查看邀请码" ON invite_codes
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- 策略2: 已认证用户可以创建邀请码
CREATE POLICY "已认证用户可创建邀请码" ON invite_codes
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- 策略3: 邀请码创建者可以删除自己的邀请码
CREATE POLICY "创建者可删除自己的邀请码" ON invite_codes
    FOR DELETE
    USING (created_by = auth.uid());

-- 7. 确保 RLS 已启用
ALTER TABLE houses ENABLE ROW LEVEL SECURITY;
ALTER TABLE house_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

-- 8. 验证策略创建成功
SELECT 
    tablename,
    policyname,
    cmd,
    qual
FROM pg_policies
WHERE tablename IN ('houses', 'house_members', 'invite_codes')
ORDER BY tablename, cmd;

-- 9. 显示执行结果
SELECT 'houses 表策略数: ' || COUNT(*) as result FROM pg_policies WHERE tablename = 'houses'
UNION ALL
SELECT 'house_members 表策略数: ' || COUNT(*) FROM pg_policies WHERE tablename = 'house_members'
UNION ALL
SELECT 'invite_codes 表策略数: ' || COUNT(*) FROM pg_policies WHERE tablename = 'invite_codes';

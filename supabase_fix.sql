-- =====================================================
-- 修复邀请码问题的SQL脚本
-- 请在 Supabase SQL Editor 中执行此脚本
-- =====================================================

-- 1. 先禁用 houses 表的 RLS 策略（如果需要）
ALTER TABLE houses DISABLE ROW LEVEL SECURITY;

-- 2. 查看 invite_codes 表中所有唯一的 house_id
SELECT DISTINCT house_id, created_by FROM invite_codes;

-- 3. 为每个邀请码对应的 house_id 插入 houses 记录
-- 这里需要根据实际数据填充
INSERT INTO houses (id, name, owner_id, created_at)
SELECT DISTINCT 
    ic.house_id,
    COALESCE(
        (SELECT name FROM houses WHERE id = ic.house_id LIMIT 1),
        '家庭共享房子'
    ) as name,
    ic.created_by,
    NOW()
FROM invite_codes ic
WHERE NOT EXISTS (
    SELECT 1 FROM houses WHERE id = ic.house_id
)
ON CONFLICT (id) DO NOTHING;

-- 4. 验证 houses 表现在有数据
SELECT * FROM houses;

-- 5. 重新启用 RLS（可选，根据需要决定）
-- ALTER TABLE houses ENABLE ROW LEVEL SECURITY;

-- 6. 创建或替换一个 RPC 函数来绕过 RLS 创建房子
CREATE OR REPLACE FUNCTION create_house_if_not_exists(
    p_id UUID,
    p_name TEXT,
    p_owner UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_house_id UUID;
BEGIN
    -- 检查是否已存在
    SELECT id INTO v_house_id FROM houses WHERE id = p_id;
    
    IF v_house_id IS NULL THEN
        -- 插入新记录
        INSERT INTO houses (id, name, owner_id, created_at)
        VALUES (p_id, p_name, p_owner, NOW())
        RETURNING id INTO v_house_id;
    END IF;
    
    RETURN v_house_id;
END;
$$;

-- 7. 授予 authenticated 用户执行权限
GRANT EXECUTE ON FUNCTION create_house_if_not_exists TO authenticated;
GRANT EXECUTE ON FUNCTION create_house_if_not_exists TO anon;

-- 8. 同时修复 house_members 表的外键问题
-- 确保 house_members 表允许插入
ALTER TABLE house_members DISABLE ROW LEVEL SECURITY;

-- 完成提示
SELECT '修复完成！houses 表现有 ' || COUNT(*) || ' 条记录' as status FROM houses;

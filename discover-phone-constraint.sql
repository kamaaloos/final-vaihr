-- Discover the phone constraint name
SELECT tc.constraint_name 
FROM information_schema.table_constraints tc 
WHERE tc.table_schema = 'auth' 
  AND tc.table_name = 'users' 
  AND tc.constraint_type = 'UNIQUE' 
  AND tc.constraint_name ILIKE '%phone%';

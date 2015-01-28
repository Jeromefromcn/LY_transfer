-- ��ȡ��Ч�ĵ�ַ 
DROP TABLE import_addressen;
CREATE TABLE import_addressen AS
SELECT *
  FROM lyboss.address_tree a
 WHERE NOT EXISTS (SELECT 'x'
          FROM lyboss.splitted_address t
         WHERE t.address_id = a.address_id)
UNION
SELECT *
  FROM lyboss.splitted_address s;
-- ������������
CREATE INDEX index_ia_id ON import_addressen(address_id);
-- ���ӵ�ַ�ȼ��ֶ�
ALTER TABLE import_addressen add addresslevelid_pk NUMBER(5);
-- ����starboss�е��ϼ���ַid
ALTER TABLE import_addressen add addressid_fk NUMBER(19);
-- ���ӵ�ַ�ȼ�����
ALTER TABLE import_addressen add add_level_code_length NUMBER(1);
-- �����ϼ���ַȫ�Ʊ���
ALTER TABLE import_addressen add parent_full_name_code VARCHAR2(1024);
-- �����ϼ���ַȫ��
ALTER TABLE import_addressen add parent_full_name VARCHAR2(1024);
-- ���Ӷ�Ӧstarboss�е�ַ��id
ALTER TABLE import_addressen add addressid_pk NUMBER(19);

-- �޸ĵڶ�����ַ �������� ����Ϣ
UPDATE import_addressen ia
   SET ia.addresslevelid_pk     = 2,
       ia.addressid_fk          = 1, --��ʼ�����ݿⴴ�� ����ʡ ��idΪ 1
       ia.add_level_code_length = 1,
       ia.parent_full_name_code = '1',
       ia.parent_full_name      = '����ʡ'
 WHERE ia.address_id = '-1' -- "��������" ��ַ��id
;

-- �����ַ�ȼ��͵�ַ���볤��
UPDATE import_addressen ia
   SET ia.addresslevelid_pk = 3, ia.add_level_code_length = 3
 WHERE ia.parent_address_id IN
       (SELECT t.address_id
          FROM import_addressen t
         WHERE t.addresslevelid_pk = 2);
UPDATE import_addressen ia
   SET ia.addresslevelid_pk = 4, ia.add_level_code_length = 4
 WHERE ia.parent_address_id IN
       (SELECT t.address_id
          FROM import_addressen t
         WHERE t.addresslevelid_pk = 3);
UPDATE import_addressen ia
   SET ia.addresslevelid_pk = 5, ia.add_level_code_length = 4
 WHERE ia.parent_address_id IN
       (SELECT t.address_id
          FROM import_addressen t
         WHERE t.addresslevelid_pk = 4);
UPDATE import_addressen ia
   SET ia.addresslevelid_pk = 6, ia.add_level_code_length = 5
 WHERE ia.parent_address_id IN
       (SELECT t.address_id
          FROM import_addressen t
         WHERE t.addresslevelid_pk = 5);
UPDATE import_addressen ia
   SET ia.addresslevelid_pk = 7, ia.add_level_code_length = 5
 WHERE ia.parent_address_id IN
       (SELECT t.address_id
          FROM import_addressen t
         WHERE t.addresslevelid_pk = 6);
UPDATE import_addressen ia
   SET ia.addresslevelid_pk = 8, ia.add_level_code_length = 5
 WHERE ia.parent_address_id IN
       (SELECT t.address_id
          FROM import_addressen t
         WHERE t.addresslevelid_pk = 7);

COMMIT;
--------------------------------------------------------------------------------
----------------������֤�ű�----------------------------------------------------
--------------------------------------------------------------------------------

SELECT * FROM import_addressen t WHERE t.addresslevelid_pk IS NULL;
SELECT * FROM import_addressen t WHERE t.addressid_fk IS NULL;
SELECT * FROM import_addressen t WHERE t.add_level_code_length IS NULL;
SELECT * FROM import_addressen t WHERE t.parent_full_name_code IS NULL;
SELECT * FROM import_addressen t WHERE t.parent_full_name IS NULL;

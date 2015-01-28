-- ��ȡ��Ч�ĵ�ַ 
DROP TABLE import_addressen;
CREATE TABLE import_addressen AS
SELECT *
  FROM lyboss.address_tree a
-- �ڵ�ַ���в���Ҫ��ֵĵ�ַ
 WHERE NOT EXISTS (SELECT 'x'
          FROM lyboss.splitted_address t
         WHERE t.address_id = a.address_id)
UNION
SELECT t.parent_address_id || t.address_name_en address_id,
       t.parent_address_id,
       0 list_order,
       '' address_name_en,
       t.address_name_en address_name,
       '' leaf,
       '' organ_code,
       '' adr_code,
       '' num,
       '' buildings_num,
       '' danyuan_num,
       '' floor,
       '' door,
       '' allnums,
       '' son_front_port_id,
       '' exchange_machine_id,
       '' light_node_id,
       '' address_name_py
-- ��ֺ������ϼ���ַ
  FROM lyboss.splitted_address t
 GROUP BY t.parent_address_id, t.address_name_en
UNION
SELECT s.address_id,
       -- �ϼ���ַΪ�� ǰ�ϼ���ַ||��ֺ��ϼ���ַ���� 
       s.parent_address_id || s.address_name_en parent_address_id,
       s.list_order,
       s.address_name_en,
       s.leaf address_name,
       s.leaf,
       s.organ_code,
       s.adr_code,
       s.num,
       s.buildings_num,
       s.danyuan_num,
       s.floor,
       s.door,
       s.allnums,
       s.son_front_port_id,
       s.exchange_machine_id,
       s.light_node_id,
       s.address_name_py
-- ��ֺ�������¼���ַ
  FROM lyboss.splitted_address s;
-- ������������
CREATE INDEX index_ia_id ON import_addressen(address_id);
-- ���ӵ�ַ�ȼ��ֶΣ�Ԥ����ʱ����
ALTER TABLE import_addressen add addresslevelid_pk NUMBER(5);
-- ���ӵ�ַ�ȼ����ȣ�Ԥ����ʱ����
ALTER TABLE import_addressen add add_level_code_length NUMBER(1);
-- ����starboss�е��ϼ���ַid�������ַʱ��д
ALTER TABLE import_addressen add addressid_fk NUMBER(19);
-- �����ϼ���ַȫ�Ʊ��룬�����ַʱ��д
ALTER TABLE import_addressen add parent_full_name_code VARCHAR2(1024);
-- �����ϼ���ַȫ�ƣ������ַʱ��д
ALTER TABLE import_addressen add parent_full_name VARCHAR2(1024);
-- ���Ӷ�Ӧstarboss�е�ַ��id�������ַʱ��д
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

-- ��ȡ��Ч�ĵ�ַ 
DROP TABLE import_raynode;
CREATE TABLE import_raynode AS
SELECT *
  FROM import_addressen a
 WHERE a.organ_code LIKE '@@LY%'
   AND a.addresslevelid_pk IN (4, 5);
-- ������������
CREATE INDEX index_ir_id ON import_raynode(address_id);
-- ���ӹ�ڵ�ȼ��ֶΣ�Ԥ����ʱ����
ALTER TABLE import_raynode add raynodelevelid_pk NUMBER(5);
-- ���ӹ�ڵ�ȼ����ȣ�Ԥ����ʱ����
ALTER TABLE import_raynode add raynode_level_code_length NUMBER(1);
-- ����starboss�е��ϼ���ڵ�id�������ڵ�ʱ��д
ALTER TABLE import_raynode add raynodeid_fk NUMBER(19);
-- �����ϼ���ڵ�ȫ�Ʊ��룬�����ڵ�ʱ��д
ALTER TABLE import_raynode add raynode_parent_full_name_code VARCHAR2(1024);


-- �����ڵ�ȼ��͹�ڵ���볤��,��һ����ڵ���ϼ���ڵ�����Ϊ���ڵ�
UPDATE import_raynode ir
   SET ir.raynodelevelid_pk         = 1,
       ir.raynode_level_code_length = 2,
       ir.raynodeid_fk              = 0
 WHERE ir.addresslevelid_pk = 4;
UPDATE import_raynode ir
   SET ir.raynodelevelid_pk = 2, ir.raynode_level_code_length = 3
 WHERE ir.addresslevelid_pk = 5;

COMMIT;


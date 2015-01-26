
-- �ڿͻ����ַ��ϵ���й��˳���Ҫ��Ӧ����Ŀͻ�
DROP TABLE import_grid_cust_mapping;
CREATE TABLE import_grid_cust_mapping AS
SELECT t.*,t.cust_id || '' cust_id_in_char
  FROM cust_address t
 WHERE EXISTS
 (SELECT 'x' FROM import_grid_info i WHERE i.addr_id = t.addr_code);

-- ������ȡ�� 'x-x-x'��ʽ���ֶΣ�����ƥ�䷽��
ALTER TABLE import_grid_cust_mapping add muroto_map VARCHAR2(20);
-- �����ֶ��ж��Ƿ�Ϊ���з���
ALTER TABLE import_grid_cust_mapping add is_in_grid VARCHAR2(5) DEFAULT 'false';
-- ���ӿͻ�id
ALTER TABLE import_grid_cust_mapping ADD custid_in_starboss NUMBER(8);

-- ����muroto_map�ֶ�Ϊ'x-x-x'��ʽ�������ϵ�Ϊ�� 
UPDATE import_grid_cust_mapping ig
   SET ig.muroto_map = regexp_substr(ig.serv_address,
                                     '([1-9]|[1-9]\d)-([1-9]|[1-9]\d)-([1-9]|[1-9]\d)$');

CREATE INDEX idx_id ON import_grid_cust_mapping(cust_id);
CREATE INDEX idx_id_char ON import_grid_cust_mapping(cust_id_in_char);
CREATE INDEX idx_map ON import_grid_cust_mapping(muroto_map);
CREATE INDEX idx_add_pk ON import_grid_cust_mapping(address_pk);
CREATE INDEX idx_custid_in_starboss ON import_grid_cust_mapping(custid_in_starboss);
COMMIT;

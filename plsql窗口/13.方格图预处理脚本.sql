-- ��ȡ����ͼ��Ϣ
DROP TABLE import_grid_info;
CREATE TABLE import_grid_info AS
SELECT gbi.addr_id,
       gbi.building_direction,
       gbi.building_style,
       gbi.floor_count,
       m.max_unit_num         unit_num, -- ȡ��Ԫ��Ϣ�������Ԫ��Ϊʵ�ʵ�Ԫ��
       m.max_unit_room_count  unit_room_count -- ȡ��Ԫ��Ϣ���������Ϊʵ�ʻ���
  FROM lyboss.grid_building_info gbi,
       (SELECT t.addr_id addr_id,
               MAX(to_number(t.unit_num)) max_unit_num,
               MAX(t.unit_room_count) max_unit_room_count
          FROM lyboss.grid_building_unit_info t
         GROUP BY t.addr_id
        -- ���Ԫ��������ڵ�Ԫ��Ϣ������
        HAVING MAX(to_number(t.unit_num)) = COUNT(*)) m -- ¥���뵥Ԫ������ʱ��
 WHERE EXISTS (SELECT 'x'
          FROM lyboss.address_tree a
         WHERE a.address_id = gbi.addr_id) -- �����뷽��󶨵ĵ�ַ
   AND gbi.unit_count > 0 -- ��Ԫ�����������
   AND gbi.floor_count > 0 -- ¥�������������
   AND gbi.addr_id = m.addr_id;

-- ������������
CREATE INDEX index_igi_id ON import_grid_info(addr_id);
-- �����ֶδ��starboss�е�ַ��id
ALTER TABLE import_grid_info add id_in_starboss NUMBER(10);

-- ��ȡ��Ԫ��Ϣ
DROP TABLE import_grid_unit_info;
CREATE TABLE import_grid_unit_info AS
SELECT * from lyboss.grid_building_unit_info gbui;

-- ������������
CREATE INDEX index_igui_id ON import_grid_unit_info(addr_id);

-- ��ȡ��Ч������Ϣ
DROP TABLE import_grid_other_info;
CREATE TABLE import_grid_other_info AS
SELECT * from lyboss.grid_building_other_info gboi;
-- ������������
CREATE INDEX index_igoi_id ON import_grid_other_info(addr_id);

COMMIT;

-- ��ȡ�����Ʒʵ����Ϣ
DROP TABLE fsboss_phy_instance;
CREATE TABLE fsboss_phy_instance AS
SELECT card.code rescode, -- ���ܿ����룬ȡ�������
       '����:' || mk.name mem,
       1 equ_type, -- ��Դ����:���ܿ�
       pd.*
  FROM fsboss.products_fs                 pd,
       fsboss.productphysicalresources_fs phy,
       fsboss.smartcards_fs               card,
       fsboss.marketingplans              mk
 WHERE pd.id = phy.productid
   AND phy.physicalresourceid = card.id
   AND pd.marketingplanid = mk.id(+)

UNION

-- �ڶ����֣�������
SELECT box.code rescode, -- �����б���
       '����:' || mk.name mem,
       2 equ_type, -- ��Դ����:������
       pd.*
  FROM fsboss.productphysicalresources_fs phy,
       fsboss.products_fs                 pd,
       fsboss.settopboxs_fs               box,
       fsboss.marketingplans              mk
 WHERE pd.id = phy.productid
   AND phy.physicalresourceid = box.id
   AND pd.marketingplanid = mk.id(+)

UNION

-- �������֣�EOC
SELECT eoc.code rescode, -- EOC����
       '����:' || mk.name mem,
       9 equ_type, -- ��Դ���ͣ�eoc
       pd.*
  FROM fsboss.products_fs                 pd,
       fsboss.productphysicalresources_fs phy, --Eoc��Դռ�ñ�
       fsboss.eocs_fs                     eoc,
       fsboss.marketingplans              mk
 WHERE pd.id = phy.productid
   AND pd.marketingplanid = mk.id(+)
   AND phy.physicalresourceid = eoc.id;

-- ��������
CREATE INDEX index_phy_instance_1 ON fsboss_phy_instance(id);
COMMIT;

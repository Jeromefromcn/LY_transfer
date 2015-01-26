CREATE OR REPLACE PACKAGE transfer_dvb_load_pkg IS

  -- Author  : HUDAZHU
  -- Created : 2014/9/1 10:31:08 AM
  -- Purpose : 

  sql_code VARCHAR2(50);
  sql_errm VARCHAR2(1000);
  v_result NUMBER(1);

  PROCEDURE load_addrinfo_prc; -- �����ַ����

  PROCEDURE load_raynode_prc; -- �����ڵ�����

  PROCEDURE load_grid_prc; -- ���뷽������

  PROCEDURE load_customer_prc; --����ͻ����˻�������˱���֧���������������ϵ

  PROCEDURE load_grid_cust_mapping_prc; -- ���뷽����ͻ��Ĺ�ϵ

  PROCEDURE load_attached_grid_mapping_prc; -- �������еķ��񣬲�����������ͻ��Ĺ�ϵ

END transfer_dvb_load_pkg;
/
CREATE OR REPLACE PACKAGE BODY transfer_dvb_load_pkg IS

  -- ������ʱ����BOSSϵͳ�ĵ�ַ����Ϣ

  PROCEDURE load_addrinfo_prc IS
    v_cnt                NUMBER;
    v_cnt_err            NUMBER;
    v_addr_count         NUMBER;
    v_addressid_pk       addressen.addressid_pk%TYPE;
    v_addresscodestr     addressen.addresscodestr%TYPE;
    v_detailaddressstr   addressen.detailaddressstr%TYPE;
    v_addressfullnamestr addressen.addressfullnamestr%TYPE;
    v_mem                addressen.mem%TYPE;
    v_result             NUMBER(1);
  
    -- ���ݵ�ǰ�����ѯ��Ӧ��ַ
    CURSOR cursor_current_level_address(level_num NUMBER) IS
      SELECT *
        FROM import_addressen ia
       WHERE ia.addresslevelid_pk = level_num;
  
  BEGIN
    v_cnt     := 0;
    v_cnt_err := 0;
    -- ѭ���ڶ������ڰ˼���ַ
    FOR level_num IN 2 .. 8 LOOP
      v_addr_count := 1;
      BEGIN
        -- ���뵱ǰ�����ַ
        FOR c_current_level_addr IN cursor_current_level_address(level_num) LOOP
          BEGIN
            v_addr_count         := v_addr_count + 1;
            v_addresscodestr     := lpad(to_char(v_addr_count),
                                         c_current_level_addr.add_level_code_length,
                                         '0'); -- ��ַ��,���ݵ�ַ���볤����0
            v_detailaddressstr   := c_current_level_addr.parent_full_name_code ||
                                    v_addresscodestr; -- ��ַȫ�Ʊ���
            v_addressfullnamestr := c_current_level_addr.parent_full_name ||
                                    c_current_level_addr.address_name; -- ��ַȫ��
            v_mem                := c_current_level_addr.address_id; -- ԭϵͳid
          
            SELECT seq_addressen.nextval INTO v_addressid_pk FROM dual;
            v_result := transfer_dvb_insert_pkg.fun_insert_addressen(p_addressid_pk       => v_addressid_pk, -- ��ַPK
                                                                     p_addressid_fk       => c_current_level_addr.addressid_fk,
                                                                     p_addresslevelid_pk  => c_current_level_addr.addresslevelid_pk,
                                                                     p_addressnamestr     => c_current_level_addr.address_name,
                                                                     p_addresscodestr     => v_addresscodestr,
                                                                     p_detailaddressstr   => v_detailaddressstr,
                                                                     p_addressabstr       => NULL,
                                                                     p_statusid           => 1, -- ��ַ״̬Ĭ����Ч
                                                                     p_mem                => v_mem,
                                                                     p_createid           => NULL,
                                                                     p_modifyid           => NULL,
                                                                     p_createcodestr      => NULL,
                                                                     p_modifycodestr      => NULL,
                                                                     p_terminalid         => NULL,
                                                                     p_salechannelid      => NULL,
                                                                     p_createdt           => SYSDATE,
                                                                     p_modifydt           => NULL,
                                                                     p_addressfullnamestr => v_addressfullnamestr);
            -- �����ַ��չ��Ϣ
            INSERT INTO addrexinfoen a
              (a.addrexinfoid_pk,
               a.addressid_pk,
               a.mem,
               a.createdt,
               a.statusid,
               a.structdt) -- ģ���źŹ�ͣ����
            VALUES
              (seq_addrexinfoen.nextval,
               v_addressid_pk,
               NULL,
               SYSDATE,
               1,
               NULL);
          
            -- ���µ�ַ��starboss�еĵ�ַid
            UPDATE import_addressen ia
               SET ia.addressid_pk = v_addressid_pk
             WHERE ia.address_id = c_current_level_addr.address_id;
            -- ������ʱ���б�����ַ�����¼���ַ���ϼ���ַid���ϼ���ַȫ�Ʊ��룬�ϼ���ַȫ��
            UPDATE import_addressen ia
               SET ia.addressid_fk          = v_addressid_pk,
                   ia.parent_full_name_code = v_detailaddressstr,
                   ia.parent_full_name      = v_addressfullnamestr
             WHERE ia.parent_address_id = c_current_level_addr.address_id;
          
            -- ��starboss�еĶ�Ӧ��ַid����¥���������ʱ�����Ӧ�ֶ�
            UPDATE import_grid_info t
               SET t.id_in_starboss =
                   (SELECT a.addressid_pk
                      FROM addressen a
                     WHERE a.mem = t.addr_id);
          
            -- ������ÿ1000���ύ
            v_cnt := v_cnt + 1;
            IF MOD(v_cnt, 1000) = 0 THEN
              COMMIT;
              transfer_dvb_log_pkg.transfer_log_prc(p_msg => v_cnt ||
                                                             ' addresses have been loaded in transfer_dvb_load_pkg.load_addrinfo_prc.');
            END IF;
          END;
        END LOOP;
      
      EXCEPTION
        WHEN OTHERS THEN
          sql_code  := SQLCODE;
          sql_errm  := SQLERRM;
          v_cnt_err := v_cnt_err + 1;
          transfer_dvb_log_pkg.transfer_err_prc(p_sql_code => sql_code,
                                                p_sql_errm => sql_errm,
                                                p_calledby => 'transfer_dvb_load_pkg.load_addrinfo_prc',
                                                p_comments => NULL,
                                                p_custid   => NULL);
      END;
    
    END LOOP;
    COMMIT;
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt_err ||
                                                   ' errors in transfer_dvb_load_pkg.load_addrinfo_prc.');
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt ||
                                                   ' addresses info loading finished.');
  END;
  PROCEDURE load_raynode_prc IS
    v_cnt              NUMBER;
    v_cnt_err          NUMBER;
    v_raynode_count    NUMBER;
    v_raynodeid_pk     raynodeen.raynodeeid_pk%TYPE;
    v_raynodeecodestr  raynodeen.raynodeecodestr%TYPE;
    v_detailraynodestr raynodeen.detailraynodestr%TYPE;
  
    -- ���ݵ�ǰ�����ѯ��Ӧ��ڵ�
    CURSOR cursor_current_level_raynode(level_num NUMBER) IS
      SELECT *
        FROM import_raynode ir
       WHERE ir.raynodelevelid_pk = level_num;
  
  BEGIN
    v_cnt     := 0;
    v_cnt_err := 0;
    FOR level_num IN 1 .. 2 LOOP
      v_raynode_count := 0;
      BEGIN
        -- ���뵱ǰ�����ڵ�
        FOR c_raynode IN cursor_current_level_raynode(level_num) LOOP
          BEGIN
            v_raynode_count    := v_raynode_count + 1;
            v_raynodeecodestr  := lpad(to_char(v_raynode_count),
                                       c_raynode.raynode_level_code_length,
                                       '0'); -- ��ڵ����,���ݹ�ڵ���볤����0
            v_detailraynodestr := c_raynode.raynode_parent_full_name_code ||
                                  v_raynodeecodestr;
            SELECT seq_raynodeen.nextval INTO v_raynodeid_pk FROM dual;
          
            INSERT INTO raynodeen
              (raynodeenamestr,
               createdt,
               covermonth,
               raynodelevelid_pk,
               raynodeeid_pk,
               statusid,
               raynodeeid_fk,
               createid,
               detailraynodestr,
               raynodeecodestr,
               createcodestr,
               mem)
            VALUES
              (c_raynode.address_name,
               SYSDATE,
               SYSDATE,
               level_num,
               v_raynodeid_pk,
               1,
               c_raynode.raynodeid_fk,
               1,
               v_detailraynodestr,
               v_raynodeecodestr,
               '00000',
               c_raynode.address_id -- ԭϵͳid
               );
          
            -- ���µ�ַ�����ڵ�Ĺ�ϵ,�������ڵ��Ӧ��ַ�������¼���ַ
            UPDATE addressen a
               SET a.raynodeeid_fk = v_raynodeid_pk
             WHERE a.detailaddressstr LIKE
                   (SELECT t.detailaddressstr
                      FROM addressen t
                     WHERE t.mem = c_raynode.address_id) || '%';
          
            -- ������ʱ���б�����ڵ������¼���ڵ���ϼ���ڵ�id���ϼ���ڵ�ȫ�Ʊ���
            UPDATE import_raynode ir
               SET ir.raynodeid_fk                  = v_raynodeid_pk,
                   ir.raynode_parent_full_name_code = v_detailraynodestr
             WHERE ir.parent_address_id = c_raynode.address_id;
          
            -- ������ÿ1000���ύ
            v_cnt := v_cnt + 1;
            IF MOD(v_cnt, 1000) = 0 THEN
              COMMIT;
              transfer_dvb_log_pkg.transfer_log_prc(p_msg => v_cnt ||
                                                             ' raynode have been loaded in transfer_dvb_load_pkg.load_raynode_prc.');
            END IF;
          END;
        END LOOP;
      
      EXCEPTION
        WHEN OTHERS THEN
          sql_code  := SQLCODE;
          sql_errm  := SQLERRM;
          v_cnt_err := v_cnt_err + 1;
          transfer_dvb_log_pkg.transfer_err_prc(p_sql_code => sql_code,
                                                p_sql_errm => sql_errm,
                                                p_calledby => 'transfer_dvb_load_pkg.load_raynode_prc',
                                                p_comments => NULL,
                                                p_custid   => NULL);
      END;
    
    END LOOP;
    COMMIT;
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt_err ||
                                                   ' errors in transfer_dvb_load_pkg.load_raynode_prc.');
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt ||
                                                   ' raynode info loading finished.');
  
  END;

  PROCEDURE load_grid_prc IS
    v_cnt             NUMBER;
    v_cnt_err         NUMBER;
    v_zero_unitid_pk  uniten.unitid_pk%TYPE; -- 0��Ԫid
    v_zero_floorid_pk flooren.floorid_pk%TYPE; -- 0¥��id
    v_unitid_pk       uniten.unitid_pk%TYPE; -- ��Ԫ��id
    v_floorid_pk      flooren.floorid_pk%TYPE; -- ¥���id
    v_murotoid_pk     murotoen.murotoid_pk%TYPE; -- ���ҵ�id
    v_grid_code       murotoen.murotocodestr%TYPE;
    v_muroto_num      NUMBER(5); -- ���ҵĸ���
    v_isenable        NUMBER(1);
    CURSOR cur_building_infos IS
      SELECT *
        FROM import_grid_info t
       WHERE EXISTS (SELECT 'x' FROM addressen a WHERE a.mem = t.addr_id);
  BEGIN
    v_cnt     := 0;
    v_cnt_err := 0;
    FOR c_building IN cur_building_infos LOOP
      BEGIN
        -- ���½�����Ĳ���
        UPDATE addrexinfoen ax
           SET ax.murotowayid   = transfer_dvb_utils_pkg.fun_get_basedata2(c_building.building_style,
                                                                           '������ʽ'),
               ax.flotrendid    = transfer_dvb_utils_pkg.fun_get_basedata2(c_building.building_direction,
                                                                           '¥��'),
               ax.floshapeid    = transfer_dvb_utils_pkg.fun_get_basedata2(c_building.building_style,
                                                                           '¥��'),
               ax.flolevelnumid = c_building.floor_count,
               ax.unitnumid     = c_building.unit_num,
               ax.flocustnumid  = c_building.unit_room_count
         WHERE ax.addressid_pk = c_building.id_in_starboss;
        -- ����0��Ԫ
        SELECT seq_uniten.nextval INTO v_zero_unitid_pk FROM dual;
        v_result := transfer_dvb_insert_pkg.fun_insert_uniten(p_unitid_pk      => v_zero_unitid_pk,
                                                              p_unitnamestr    => 'UnitInfo',
                                                              p_unitcodestr    => 'UnitInfo',
                                                              p_unitnum        => 0,
                                                              p_addressid      => c_building.id_in_starboss,
                                                              p_subnum         => 0, -- ���з����� �������з������޸�
                                                              p_statusid       => 1,
                                                              p_mem            => NULL,
                                                              p_createid       => 1,
                                                              p_modifyid       => NULL,
                                                              p_createcodestr  => '00000',
                                                              p_modifycodestr  => NULL,
                                                              p_terminalid     => NULL,
                                                              p_salechannelid  => NULL,
                                                              p_createdt       => SYSDATE,
                                                              p_modifydt       => NULL,
                                                              p_salechannelid1 => NULL,
                                                              p_operareaid     => NULL);
        -- ����0¥��
        SELECT seq_flooren.nextval INTO v_zero_floorid_pk FROM dual;
        v_result := transfer_dvb_insert_pkg.fun_insert_flooren(p_floorid_pk     => v_zero_floorid_pk,
                                                               p_floornamestr   => 'RestInfo',
                                                               p_floorcodestr   => 'RestInfo',
                                                               p_floornum       => 0,
                                                               p_addressid      => c_building.id_in_starboss,
                                                               p_statusid       => 1,
                                                               p_mem            => NULL,
                                                               p_createid       => 1,
                                                               p_modifyid       => NULL,
                                                               p_createcodestr  => '00000',
                                                               p_modifycodestr  => NULL,
                                                               p_terminalid     => NULL,
                                                               p_salechannelid  => NULL,
                                                               p_createdt       => SYSDATE,
                                                               p_modifydt       => NULL,
                                                               p_salechannelid1 => NULL,
                                                               p_operareaid     => NULL);
      
        -- ����¥��                                                     
        FOR floornum IN 1 .. c_building.floor_count LOOP
          SELECT seq_flooren.nextval INTO v_floorid_pk FROM dual;
          v_result := transfer_dvb_insert_pkg.fun_insert_flooren(p_floorid_pk     => v_floorid_pk,
                                                                 p_floornamestr   => 'FloorInfo',
                                                                 p_floorcodestr   => 'FloorInfo',
                                                                 p_floornum       => floornum,
                                                                 p_addressid      => c_building.id_in_starboss,
                                                                 p_statusid       => 1,
                                                                 p_mem            => NULL,
                                                                 p_createid       => 1,
                                                                 p_modifyid       => NULL,
                                                                 p_createcodestr  => '00000',
                                                                 p_modifycodestr  => NULL,
                                                                 p_terminalid     => NULL,
                                                                 p_salechannelid  => NULL,
                                                                 p_createdt       => SYSDATE,
                                                                 p_modifydt       => NULL,
                                                                 p_salechannelid1 => NULL,
                                                                 p_operareaid     => NULL);
        END LOOP;
      
        -- ���ɵ�Ԫ
        FOR unitnum IN 1 .. c_building.unit_num LOOP
        
          -- ��Ϊÿ����Ԫ�Ļ��������̶�����Ҫȡ����Ԫ��Ϣ���еĻ�����
          SELECT t.unit_room_count
            INTO v_muroto_num
            FROM import_grid_unit_info t
           WHERE t.addr_id = c_building.addr_id
             AND t.unit_num = unitnum;
        
          SELECT seq_uniten.nextval INTO v_unitid_pk FROM dual;
          v_result := transfer_dvb_insert_pkg.fun_insert_uniten(p_unitid_pk      => v_unitid_pk,
                                                                p_unitnamestr    => 'UnitInfo',
                                                                p_unitcodestr    => 'UnitInfo',
                                                                p_unitnum        => unitnum,
                                                                p_addressid      => c_building.id_in_starboss,
                                                                p_subnum         => v_muroto_num,
                                                                p_statusid       => 1,
                                                                p_mem            => NULL,
                                                                p_createid       => 1,
                                                                p_modifyid       => NULL,
                                                                p_createcodestr  => '00000',
                                                                p_modifycodestr  => NULL,
                                                                p_terminalid     => NULL,
                                                                p_salechannelid  => NULL,
                                                                p_createdt       => SYSDATE,
                                                                p_modifydt       => NULL,
                                                                p_salechannelid1 => NULL,
                                                                p_operareaid     => NULL);
          --ѭ��¥��                                                     
          FOR floornum IN 1 .. c_building.floor_count LOOP
            -- ���ɷ���
            FOR murotonum IN 1 .. v_muroto_num LOOP
              SELECT seq_murotoen.nextval INTO v_murotoid_pk FROM dual;
              v_grid_code := unitnum || '-' || floornum || '-' || murotonum;
            
              v_isenable := transfer_dvb_utils_pkg.fun_is_grid_enable(c_building.addr_id,
                                                                      floornum,
                                                                      unitnum,
                                                                      murotonum);
              v_result   := transfer_dvb_insert_pkg.fun_insert_murotoen(p_murotoid_pk    => v_murotoid_pk,
                                                                        p_murotonamestr  => v_grid_code,
                                                                        p_murotocodestr  => v_grid_code,
                                                                        p_murotonum      => murotonum,
                                                                        p_addressid      => c_building.id_in_starboss,
                                                                        p_floorid        => v_zero_floorid_pk +
                                                                                            floornum, -- ¥��Ϊ0��pk�ӵ�ǰ¥��
                                                                        p_unitid         => v_unitid_pk, -- ��Ԫ
                                                                        p_isenable       => v_isenable,
                                                                        p_statusid       => 1,
                                                                        p_mem            => NULL,
                                                                        p_createid       => 1,
                                                                        p_modifyid       => NULL,
                                                                        p_createcodestr  => '00000',
                                                                        p_modifycodestr  => NULL,
                                                                        p_terminalid     => NULL,
                                                                        p_salechannelid  => NULL,
                                                                        p_createdt       => SYSDATE,
                                                                        p_modifydt       => NULL,
                                                                        p_salechannelid1 => NULL,
                                                                        p_operareaid     => NULL);
            END LOOP;
          END LOOP;
        
        END LOOP;
      
        -- �������ֶ��ύ
        v_cnt := v_cnt + 1;
        IF MOD(v_cnt, 1000) = 0 THEN
          COMMIT;
          transfer_dvb_log_pkg.transfer_log_prc(p_msg => v_cnt ||
                                                         ' addresses have been loaded in transfer_dvb_load_pkg.load_addrinfo_prc.');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          sql_code  := SQLCODE;
          sql_errm  := SQLERRM;
          v_cnt_err := v_cnt_err + 1;
          transfer_dvb_log_pkg.transfer_err_prc(p_sql_code => sql_code,
                                                p_sql_errm => sql_errm,
                                                p_calledby => 'transfer_dvb_load_pkg.load_grid_prc',
                                                p_comments => NULL,
                                                p_custid   => NULL);
      END;
    END LOOP;
    COMMIT;
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt_err ||
                                                   ' errors in transfer_dvb_load_pkg.load_grid_prc.');
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt ||
                                                   ' grid infos loading finished.');
  
  END;

  PROCEDURE load_customer_prc IS
  
    v_cnt                NUMBER;
    v_cnt_err            NUMBER;
    v_customerid         customeren.customerid_pk%TYPE;
    v_accountid_pk       accounten.accountid_pk%TYPE;
    v_acctbookid_pk      acctbooken.acctbookid_pk%TYPE;
    v_payprojectid_pk    payprojecten.payprojectid_pk%TYPE;
    v_accbalanceobjid_pk acctbalanceobjen.accbalanceobjid_pk%TYPE;
  
    v_mr_salechannelid customeren.salechannelid1%TYPE;
  
    v_mr_createcodestr customeren.createcodestr%TYPE;
    v_mr_createid      customeren.createid%TYPE;
  
    v_customerlevelid   customeren.customerlevelid%TYPE;
    v_operareaid        operareaen.operareaid_pk%TYPE;
    v_salechannelid     customeren.salechannelid1%TYPE;
    v_certificatetypeid customeren.certificatetypeid%TYPE;
  
    v_societyid customeren.societyid%TYPE;
  
    v_cust_mark VARCHAR2(50);
    CURSOR c_customer IS
    
      SELECT NULL customerid_fk,
             
             decode(cust.cust_type, 1, 0, 2, 1, 0) customertypeid,
             
             -- �ͻ�������ȥ���ո�
             REPLACE(cust.name, ' ', '') customernamestr,
             --�ͻ����룻���չ�����������
             NULL customercodestr,
             
             -- ֤������
             cust.social_id_type certificatetypeid,
             
             -- ֤������
             REPLACE(cust.social_id, ' ', '') certcodestr,
             
             -- ��ϵ�绰
             REPLACE(cust.cust_contact_tel, ' ', '') linktelstr,
             
             -- �ƶ��绰
             REPLACE(cust.mobile, ' ', '') mobilestr,
             
             -- ��ϵ��
             nvl(REPLACE(cust.cust_contact_name, ' ', ''), cust.name) linkmanstr, -- ��ϵ�ˣ�ȡ�ÿո�
             
             cust. postalcode zipcodestr,
             
             -- �ͻ���ϵ��ַ��ȡ ������ϵͳ�ڵĿͻ������ĵ�ַ��Ϣ
             ca.addressnamestr_fk || ca.serv_address contactaddrstr,
             
             NULL detailaddrcodestr,
             
             -- ע�����ڣ�ԭϵͳ��û��ע������
             nvl(cust.create_date,
                 to_date('20000101 10:10:10', 'yyyymmdd hh24:mi:ss')) enroldt,
             
             --�Ա�
             decode(��cust.gender, 'M', 0, 'F', 1, NULL) sexstr,
             
             NULL vacationid,
             --����
             cust.cust_birth birthdaydt,
             
             NULL certenddt,
             NULL certregionaddrstr,
             NULL companytypestr,
             --�ͻ���ַ
             ca.address_pk custaddressid,
             
             -- ʹ�þ�ϵͳ��ʶ ��¼SMSϵͳ�Ŀͻ�����
             TRIM(cust.cust_no) oldsysid,
             
             --������
             ��cust.cust_class_id societyid,
             --��Ӫ���򣺸�˳
             cust.organ_code operareaid,
             --�ͻ�״̬
             cust.state customerstatusid,
             --��������
             NULL salechannelid,
             --��ϸ��ַ(��ȡ��ַ��� ����1-1-1)
             substr(ca.serv_address, length(ca.addressnamestr)) customeraddrstr,
             cust.e_mail emailstr,
             NULL faxcodestr,
             NULL companyaddrstr,
             NULL companynetaddrstr,
             NULL vipstr,
             NULL logoffreasonid,
             NULL logoffdt,
             NULL restorereasonid,
             NULL restoredt,
             NULL vodflagid,
             cust.remark mem,
             
             NULL createid,
             NULL modifyid,
             NULL createcodestr,
             NULL modifycodestr,
             NULL terminalid,
             nvl(cust.create_date,
                 to_date('20000101 10:10:10', 'yyyymmdd hh24:mi:ss')) createdt,
             NULL modifydt,
             --ԭϵͳ�е�ǰ�ͻ�ID
             cust.cust_id addinfostr2,
             --ԭϵͳ�е�ǰ�ͻ����ϼ��ͻ�ID
             ��cust.parent_id addinfostr3,
             -- �ͻ�����
             cust.vip_type customerlevelid
      
        FROM lyboss.cust  cust, --�ͻ���
             cust_address ca
       WHERE cust.cust_id = ca.cust_id
         AND cust.state <> '70H';
  
  BEGIN
  
    v_cnt     := 0;
    v_cnt_err := 0;
  
    v_cust_mark := '����';
  
    v_mr_salechannelid := 1;
  
    v_mr_createcodestr := '00000';
    v_mr_createid      := '1';
  
    FOR v_customer IN c_customer LOOP
    
      BEGIN
      
        SELECT seq_customeren.nextval INTO v_customerid FROM dual;
      
        -- Ӫ������
        --v_salechannelid := transfer_dvb_utils_pkg.fun_get_salechannel(v_customer.userid);
        --if v_salechannelid = 0 then  -- ���û�в鵽��Ӧ��Ӫ����������ȡĬ�� Ӫ������
        v_salechannelid := v_mr_salechannelid;
        --end if;
      
        v_result := transfer_dvb_insert_pkg.fun_insert_customeren(p_customerid_pk   => v_customerid,
                                                                  p_addressid       => v_customer.custaddressid,
                                                                  p_customerid_fk   => v_customer.customerid_fk,
                                                                  p_customernamestr => v_customer.customernamestr,
                                                                  p_customercodestr => lpad(v_customerid,
                                                                                            12,
                                                                                            '0'), -- �ͻ�����, 
                                                                  p_custtypeid      => v_customer.customertypeid, -- �ͻ����� 
                                                                  
                                                                  p_certificatetypeid => v_certificatetypeid, -- ֤������,
                                                                  p_certcodestr       => v_customer.certcodestr, -- ֤������
                                                                  p_linktelstr        => v_customer.linktelstr, -- ��ϵ�绰
                                                                  p_mobilestr         => v_customer.mobilestr, -- �ֻ�
                                                                  p_customeraddrstr   => v_customer.customeraddrstr, -- ��ϸ��ַ
                                                                  p_customerstatusid  => 1,
                                                                  
                                                                  p_linkmanstr        => v_customer.linkmanstr, -- ��ϵ��
                                                                  p_zipcodestr        => v_customer.zipcodestr,
                                                                  p_contactaddrstr    => v_customer.contactaddrstr, -- ��ϵ��ַ
                                                                  p_detailaddrcodestr => v_customer.detailaddrcodestr,
                                                                  p_pwdstr            => transfer_dvb_utils_pkg.cust_pwd,
                                                                  p_enroldt           => v_customer.enroldt,
                                                                  p_salechannelid1    => v_customer.salechannelid, --��������
                                                                  p_sexstr            => v_customer.sexstr,
                                                                  p_vacationid        => v_customer.vacationid,
                                                                  p_birthdaydt        => v_customer.birthdaydt,
                                                                  p_societyid         => v_societyid, -- ������
                                                                  p_certenddt         => v_customer.certenddt,
                                                                  p_certregionaddrstr => v_customer.certregionaddrstr,
                                                                  p_companytypestr    => v_customer.companytypestr,
                                                                  p_oldsysid          => v_customer.oldsysid,
                                                                  p_emailstr          => v_customer.emailstr,
                                                                  p_faxcodestr        => v_customer.faxcodestr,
                                                                  p_companyaddrstr    => v_customer.companyaddrstr,
                                                                  p_companynetaddrstr => v_customer.companynetaddrstr,
                                                                  p_customerlevelid   => v_customerlevelid, -- �ͻ�����
                                                                  p_vipstr            => v_customer.vipstr,
                                                                  p_logoffreasonid    => v_customer.logoffreasonid,
                                                                  p_logoffdt          => v_customer.logoffdt,
                                                                  p_restorereasonid   => v_customer.restorereasonid,
                                                                  p_restoredt         => v_customer.restoredt,
                                                                  p_vodflagid         => v_customer.vodflagid,
                                                                  p_mem               => v_customer.mem,
                                                                  p_createid          => v_mr_createid,
                                                                  p_modifyid          => v_customer.modifyid,
                                                                  p_createcodestr     => v_mr_createcodestr,
                                                                  p_modifycodestr     => v_customer.modifycodestr,
                                                                  p_terminalid        => v_customer.terminalid,
                                                                  p_salechannelid     => v_customer.salechannelid,
                                                                  p_createdt          => v_customer.createdt,
                                                                  p_modifydt          => v_customer.modifydt,
                                                                  p_operareaid        => 1,
                                                                  -- ��Ӫ����
                                                                  p_addinfostr1   => v_cust_mark,
                                                                  p_addinfostr2   => v_customer.addinfostr2,
                                                                  p_addinfostr3   => v_customer.addinfostr3,
                                                                  p_addinfostr4   => NULL,
                                                                  p_encryptpwdstr => '123456'
                                                                  
                                                                  );
        -- Ϊ�ͻ������˻�
        SELECT seq_accounten.nextval INTO v_accountid_pk FROM dual;
        v_result := transfer_dvb_insert_pkg.fun_insert_accounten(p_accountid_pk   => v_accountid_pk, -- �˻�PK
                                                                 p_customerid_pk  => v_customerid, -- �ͻ�PK
                                                                 p_accountcodestr => lpad(v_accountid_pk,
                                                                                          12,
                                                                                          '0'), -- �˻����룬�˻�PK ��λ 0���ܳ� 12λ
                                                                 -- �˻����ƣ��ͻ����� + ҵ�����ƣ���Ҫ����ϵͳ�������趨��ȷ���Ƿ�Ϊ�ĸ�ҵ�񴴽��˻���
                                                                 p_accountnamestr => v_customer.customernamestr ||
                                                                                     '-����ҵ���ʻ�',
                                                                 p_isdefaultid    => 1, -- �Ƿ�Ĭ���ʻ���������
                                                                 p_postwayid      => 0, -- �˵��ʼķ�ʽ����ͨ�ʼ�
                                                                 p_postaddrstr    => v_customer.contactaddrstr, -- �ʼĵ�ַ���ͻ���ϵ��ַ
                                                                 p_zipcodestr     => NULL,
                                                                 p_logoffreasonid => NULL,
                                                                 p_businessid     => 0, --����ҵ�񣺹���ҵ�񣬿��Դ���������˱�������֧�ֶ�ҵ��
                                                                 p_statusid       => 1, -- ״̬����Ч
                                                                 p_mem            => NULL,
                                                                 p_createid       => v_customer.createid,
                                                                 p_modifyid       => v_customer.modifyid,
                                                                 p_createcodestr  => NULL,
                                                                 p_modifycodestr  => NULL,
                                                                 p_terminalid     => NULL,
                                                                 p_salechannelid  => NULL,
                                                                 p_createdt       => v_customer.createdt,
                                                                 p_modifydt       => v_customer.modifydt,
                                                                 p_salechannelid1 => NULL,
                                                                 p_operareaid     => v_operareaid
                                                                 -- ��Ӫ����
                                                                 );
      
        -- ��������˱�
        SELECT seq_acctbooken.nextval INTO v_acctbookid_pk FROM dual;
        v_result := transfer_dvb_insert_pkg.fun_insert_acctbooken(p_acctbookid_pk    => v_acctbookid_pk,
                                                                  p_balancetypeid_pk => 0,
                                                                  p_acctbooknamestr  => v_customer.customernamestr ||
                                                                                        '-����ҵ���ʻ���ͨԤ������',
                                                                  p_acctbookcodestr  => lpad(v_acctbookid_pk,
                                                                                             12,
                                                                                             '0') || '0',
                                                                  p_startdt          => v_customer.createdt,
                                                                  p_enddt            => NULL,
                                                                  p_balanceid        => 0, -- ���
                                                                  p_cycle_upperid    => 0, -- �۷���߶�
                                                                  p_cycle_lowerid    => 0, -- �۷���Ͷ�
                                                                  p_statusid         => 1, -- ״̬ ��Ч
                                                                  p_mem              => NULL,
                                                                  p_createid         => v_customer.createid,
                                                                  p_modifyid         => v_customer.modifyid,
                                                                  p_createcodestr    => NULL,
                                                                  p_modifycodestr    => NULL,
                                                                  p_terminalid       => NULL,
                                                                  p_salechannelid    => NULL,
                                                                  p_createdt         => v_customer.createdt,
                                                                  p_salechannelid1   => NULL,
                                                                  p_operareaid       => NULL, -- ��Ӫ����
                                                                  p_modifydt         => v_customer.modifydt,
                                                                  p_deductpriid      => 0, -- �ۿ����ȼ� 0 Ϊ���
                                                                  p_customerid       => v_customerid, -- �ͻ���ʶ
                                                                  p_objtypeid        => 1, -- ����������  1���˻�
                                                                  p_objid            => v_accountid_pk); -- �ʻ�PK��������
      
        -- ����֧������
        SELECT seq_payprojecten.nextval INTO v_payprojectid_pk FROM dual;
      
        v_result := transfer_dvb_insert_pkg.fun_insert_payprojecten(p_payprojectid_pk    => v_payprojectid_pk,
                                                                    p_paymethodid_pk     => 111, -- ��������  �ֽ�
                                                                    p_acctbookid_pk      => v_acctbookid_pk, -- ����˱�PK
                                                                    p_accountid_pk       => v_accountid_pk, -- �˻�PK
                                                                    p_paytypeid          => 1, -- ���ѷ�ʽ
                                                                    p_priid              => 0, -- ���ȼ�
                                                                    p_bankid             => NULL,
                                                                    p_bankaccountcodestr => NULL,
                                                                    p_bankaccountnamestr => NULL,
                                                                    p_bankaccounttypestr => NULL,
                                                                    p_creditvalidatedt   => NULL,
                                                                    p_mem                => NULL,
                                                                    p_createid           => v_customer.createid,
                                                                    p_modifyid           => v_customer.modifyid,
                                                                    p_createcodestr      => NULL,
                                                                    p_modifycodestr      => NULL,
                                                                    p_terminalid         => NULL,
                                                                    p_salechannelid      => NULL,
                                                                    p_createdt           => v_customer.createdt,
                                                                    p_modifydt           => v_customer.modifydt,
                                                                    p_salechannelid1     => NULL,
                                                                    p_operareaid         => v_operareaid, -- ��Ӫ����
                                                                    p_statusid           => 1);
        -- �����������ϵ
        SELECT seq_acctbalanceobjen.nextval
          INTO v_accbalanceobjid_pk
          FROM dual;
      
        v_result := transfer_dvb_insert_pkg.fun_insert_acctbalanceobjen(p_accbalanceobjid_pk => v_accbalanceobjid_pk,
                                                                        p_acctbookid_pk      => v_acctbookid_pk, -- ����˱�PK
                                                                        p_objtypeid          => 1, -- ����˱��������ʻ���1
                                                                        p_objid              => v_accountid_pk, -- �˻�PK
                                                                        p_mem                => NULL,
                                                                        p_createid           => v_customer.createid,
                                                                        p_modifyid           => v_customer.modifyid,
                                                                        p_createcodestr      => NULL,
                                                                        p_modifycodestr      => NULL,
                                                                        p_terminalid         => NULL,
                                                                        p_salechannelid      => NULL,
                                                                        p_createdt           => v_customer.createdt,
                                                                        p_salechannelid1     => NULL,
                                                                        p_operareaid         => v_operareaid, -- ��Ӫ����
                                                                        p_modifydt           => v_customer.modifyid,
                                                                        p_statusid           => 1);
        -- ����Ԥ�������ݣ����starboss�Ŀͻ�id
        UPDATE import_grid_cust_mapping t
           SET t.custid_in_starboss = v_customerid
         WHERE t.cust_id = v_customer.addinfostr2;
      
        v_cnt := v_cnt + 1;
        IF MOD(v_cnt, 10000) = 0 THEN
          COMMIT;
          transfer_dvb_log_pkg.transfer_log_prc(p_msg => v_cnt ||
                                                         ' customers have been loaded in transfer_dvb_load_pkg.load_customer_prc.');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          sql_code  := SQLCODE;
          sql_errm  := SQLERRM;
          v_cnt_err := v_cnt_err + 1;
          transfer_dvb_log_pkg.transfer_err_prc(p_sql_code => sql_code,
                                                p_sql_errm => sql_errm,
                                                p_calledby => 'transfer_dvb_load_pkg.load_customer_prc',
                                                p_comments => TRIM(v_customer.oldsysid),
                                                p_custid   => NULL);
      END;
    END LOOP;
    COMMIT;
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt_err ||
                                                   ' errors in transfer_dvb_load_pkg.load_customer_prc.');
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt ||
                                                   ' customer_indiv info loading finished.');
  
  END;
  PROCEDURE load_grid_cust_mapping_prc IS
    v_cnt                 NUMBER;
    v_cnt_err             NUMBER;
    v_customerid          customeren.customerid_pk%TYPE;
    v_murotoid            murotoen.murotoid_pk%TYPE;
    v_count_for_existence NUMBER;
    CURSOR cur_mapping IS
      SELECT *
        FROM import_grid_cust_mapping t /*WHERE t.cust_id = 970243*/
      ;
  BEGIN
    v_cnt     := 0;
    v_cnt_err := 0;
    FOR c_mapping IN cur_mapping LOOP
      BEGIN
      
        SELECT COUNT(*)
          INTO v_count_for_existence
          FROM murotoen m
         WHERE m.addressid = c_mapping.address_pk
           AND m.murotocodestr = c_mapping.muroto_map;
      
        IF v_count_for_existence > 0 THEN
          SELECT m.murotoid_pk
            INTO v_murotoid
            FROM murotoen m
           WHERE m.addressid = c_mapping.address_pk
             AND m.murotocodestr = c_mapping.muroto_map;
        
          INSERT INTO muroto_custen
          VALUES
            (v_murotoid, c_mapping.custid_in_starboss);
          -- ����ܹ���������������� is_in_grid �ֶ�Ϊtrue
          UPDATE import_grid_cust_mapping i
             SET i.is_in_grid = 'true'
           WHERE i.cust_id = c_mapping.cust_id;
        
          v_cnt := v_cnt + 1;
          IF MOD(v_cnt, 10000) = 0 THEN
            COMMIT;
            transfer_dvb_log_pkg.transfer_log_prc(p_msg => v_cnt ||
                                                           ' mapping have been created in transfer_dvb_load_pkg.load_grid_cust_mapping_prc.');
          END IF;
        
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          sql_code  := SQLCODE;
          sql_errm  := SQLERRM;
          v_cnt_err := v_cnt_err + 1;
          transfer_dvb_log_pkg.transfer_err_prc(p_sql_code => sql_code,
                                                p_sql_errm => sql_errm,
                                                p_calledby => 'transfer_dvb_load_pkg.load_grid_cust_mapping_prc',
                                                p_comments => c_mapping.cust_id,
                                                p_custid   => v_customerid);
      END;
    END LOOP;
    COMMIT;
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt_err ||
                                                   ' errors in transfer_dvb_load_pkg.load_grid_cust_mapping_prc.');
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt ||
                                                   ' mapping info creating finished.');
  
  END;

  PROCEDURE load_attached_grid_mapping_prc IS
    v_cnt               NUMBER;
    v_cnt_err           NUMBER;
    v_murotoid_pk       murotoen.murotoid_pk%TYPE;
    v_zero_unitid_pk    uniten.unitid_pk%TYPE;
    v_zero_floorid_pk   flooren.floorid_pk%TYPE;
    v_count_attachement NUMBER(5);
    CURSOR cur_attached_grids IS
      SELECT *
        FROM import_grid_cust_mapping t
       WHERE t.is_in_grid = 'false';
  
  BEGIN
    v_cnt     := 0;
    v_cnt_err := 0;
    FOR c_attachment IN cur_attached_grids LOOP
      BEGIN
        SELECT t.unitid_pk
          INTO v_zero_unitid_pk
          FROM uniten t
         WHERE t.unitnum = 0
           AND t.addressid = c_attachment.address_pk;
        SELECT t.floorid_pk
          INTO v_zero_floorid_pk
          FROM flooren t
         WHERE t.floornum = 0
           AND t.addressid = c_attachment.address_pk;
        -- ����0��Ԫ������������һ�����з������������1
        UPDATE uniten t
           SET t.subnum = t.subnum + 1
         WHERE t.unitid_pk = v_zero_unitid_pk;
        -- �������з���
        -- ��ѯĿǰ���з�������Ϊ���з���ı���
        SELECT t.subnum
          INTO v_count_attachement
          FROM uniten t
         WHERE t.unitid_pk = v_zero_unitid_pk;
        SELECT seq_murotoen.nextval INTO v_murotoid_pk FROM dual;
        v_result := transfer_dvb_insert_pkg.fun_insert_murotoen(p_murotoid_pk    => v_murotoid_pk,
                                                                p_murotonamestr  => 'Y' || '-' ||
                                                                                    v_count_attachement,
                                                                p_murotocodestr  => 'Y' || '-' ||
                                                                                    v_count_attachement,
                                                                p_murotonum      => v_count_attachement,
                                                                p_addressid      => c_attachment.address_pk,
                                                                p_floorid        => v_zero_floorid_pk,
                                                                p_unitid         => v_zero_unitid_pk, -- ��Ԫ
                                                                p_isenable       => 1,
                                                                p_statusid       => 1,
                                                                p_mem            => c_attachment.serv_address,
                                                                p_createid       => 1,
                                                                p_modifyid       => NULL,
                                                                p_createcodestr  => '00000',
                                                                p_modifycodestr  => NULL,
                                                                p_terminalid     => NULL,
                                                                p_salechannelid  => NULL,
                                                                p_createdt       => SYSDATE,
                                                                p_modifydt       => NULL,
                                                                p_salechannelid1 => NULL,
                                                                p_operareaid     => NULL);
        -- �����з�����ͻ�
      
        INSERT INTO muroto_custen
        VALUES
          (v_murotoid_pk, c_attachment.custid_in_starboss);
      
        v_cnt := v_cnt + 1;
        IF MOD(v_cnt, 10000) = 0 THEN
          COMMIT;
          transfer_dvb_log_pkg.transfer_log_prc(p_msg => v_cnt ||
                                                         ' mapping have been created in transfer_dvb_load_pkg.load_attached_grid_mapping_prc.');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          sql_code  := SQLCODE;
          sql_errm  := SQLERRM;
          v_cnt_err := v_cnt_err + 1;
          transfer_dvb_log_pkg.transfer_err_prc(p_sql_code => sql_code,
                                                p_sql_errm => sql_errm,
                                                p_calledby => 'transfer_dvb_load_pkg.load_attached_grid_mapping_prc',
                                                p_comments => NULL,
                                                p_custid   => NULL);
      END;
    END LOOP;
    COMMIT;
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt_err ||
                                                   ' errors in transfer_dvb_load_pkg.load_attached_grid_mapping_prc.');
    transfer_dvb_log_pkg.transfer_log_prc(p_msg => 'total ' || v_cnt ||
                                                   ' attached grids info creating finished.');
  END;

END transfer_dvb_load_pkg;
/

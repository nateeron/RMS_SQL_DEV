   [HttpGet("secondQuery")]
        public async Task<IActionResult> GetSecondReport(long Year, long ZoneId, long ProvinceID, long DistrictID, long SubDistrictID,
            long VillageID, long LGO, long Indicators, long IsHouseholder, long refRegionId)
        {
            // Optimized query with improved WHERE clauses and subquery
            string sqlQuery = @"
                WITH gender_stats AS (
                    -- Pre-aggregate gender statistics for better performance
                    SELECT 
                        ref_house_data_id,
                        SUM(CASE WHEN gender = '1' THEN 1 ELSE 0 END) AS male,
                        SUM(CASE WHEN gender = '2' THEN 1 ELSE 0 END) AS female,
                        SUM(CASE WHEN gender = '3' THEN 1 ELSE 0 END) AS lgbti
                    FROM t_house_member
                    WHERE is_foreigner = 'f'
                    GROUP BY ref_house_data_id
                )
                SELECT 
                    ind.group_id AS GroupId,
                    ind.INDICATOR AS indid,
                    ind.INDICATOR || ' ' || ind.indicator_name AS Indicators,
                    ind.group_name AS GroupName,
                    pv.id AS ProvincID,
                    pv.name_th AS ProvincName,
                    ap.id AS DistrictID,
                    ap.name_th AS DistrictName,
                    tb.id AS SubDistrictID,
                    tb.name_th AS SubDistrictName,
                    v.id AS MooID,
                    v.moo AS Moo,
                    v.name_th AS Village,
                    thd.house_no AS AddressNo,
                    thd.house_nearby AS AddressNoNear,
                    thd.house_code AS HouseCode,
                    pf.name AS Title,
                    thm.first_name AS FirstName,
                    thm.last_name AS LastName,
                    thm.identification_card AS CitizenID,
                    thm.age AS AgeYear,
                    thm.age_month AS AgeMonth,
                    opc.name AS Occupation,
                    ed.name AS Education,
                    rl.id AS RelationshipID,
                    rl.name AS Relationship,
                    mdt.id AS DistrictTypeId,
                    mdt.name_th AS DistrictTypeName,
                    r.name AS Religion,
                    CASE 
                        WHEN thm.is_self_reliance = 'T' THEN 'ช่วยเหลือตัวเองได้' 
                        ELSE 'ช่วยเหลือตัวเองไม่ได้' 
                    END AS SelfReliance,
                    CASE 
                        WHEN thm.is_normal = 'T' AND thm.is_disabled = 'F' AND thm.is_chronic_patient = 'F' THEN 'ปกติ'
                        WHEN thm.is_normal = 'F' AND thm.is_disabled = 'T' THEN 'ผู้พิการ'
                        WHEN thm.is_normal = 'F' AND thm.is_chronic_patient = 'T' THEN 'ผู้ป่วยเรื้อรัง' 
                        ELSE '' 
                    END AS PhysicalStatus,
                    CASE WHEN rl.id = 1 THEN s.unit_all ELSE NULL END AS UnitAll,
                    CASE WHEN rl.id = 1 THEN s.unit_passed ELSE NULL END AS UnitPassed,
                    CASE WHEN rl.id = 1 THEN s.passed ELSE NULL END AS passed,
                    CASE WHEN rl.id = 1 THEN s.failed ELSE NULL END AS failed,
                    CASE WHEN rl.id = 1 THEN tgen.male ELSE NULL END AS male,
                    CASE WHEN rl.id = 1 THEN tgen.female ELSE NULL END AS female,
                    CASE WHEN rl.id = 1 THEN tgen.lgbti ELSE NULL END AS lgbti,
                    CASE WHEN rl.id = 1 THEN 1 ELSE 0 END AS hh,
                    s.is_unit AS IsUnit
                FROM m_indicator ind
                INNER JOIN jptreport_summary s ON s.INDICATOR = ind.question
                LEFT JOIN t_house_data thd ON thd.id = s.ref_house_data_id
                LEFT JOIN m_district_type mdt ON thd.ref_district_type_id = mdt.id
                LEFT JOIN t_house_member thm ON thd.id = thm.ref_house_data_id
                LEFT JOIN m_occupation opc ON thm.ref_occupation_id = opc.id
                LEFT JOIN m_education ed ON thm.ref_education_id = ed.id
                LEFT JOIN m_relationship rl ON thm.ref_relationship_id = rl.id
                LEFT JOIN m_prefix pf ON thm.ref_prefix_id = pf.id
                LEFT JOIN m_religion r ON thm.ref_religion_id = r.id
                LEFT JOIN m_province pv ON thd.ref_province_id = pv.id
                LEFT JOIN m_amphur ap ON thd.ref_amphur_id = ap.id
                LEFT JOIN m_tumbol tb ON thd.ref_tumbol_id = tb.id
                LEFT JOIN m_village v ON thd.ref_village_id = v.id
                LEFT JOIN gender_stats tgen ON thd.id = tgen.ref_house_data_id
                WHERE s.failed = 1 
                    AND s.indicator = :indicators
                    -- Optimized WHERE clauses: Use OR/AND instead of CASE WHEN for better index usage
                    AND (:isHouseholder = 0 AND thm.ref_relationship_id = '1' OR :isHouseholder != 0 AND thm.is_foreigner = 'f')
                    AND (:ZoneID = 0 OR thd.ref_region_id = :ZoneID)
                    AND (:ProvinceID = 0 OR thd.ref_province_id = :ProvinceID)
                    AND (:DistrictID = 0 OR thd.ref_amphur_id = :DistrictID)
                    AND (:SubDistrictID = 0 OR thd.ref_tumbol_id = :SubDistrictID)
                    AND (:VillageID = 0 OR thd.ref_village_id = :VillageID)
                    AND (:LGOID = 0 OR thd.ref_district_type_id = :LGOID)
                GROUP BY 
                    ind.group_id, ind.INDICATOR, ind.indicator_name, ind.question, ind.group_name,
                    pv.id, pv.name_th, ap.id, ap.name_th, tb.id, tb.name_th, mdt.id, mdt.name_th,
                    v.id, v.moo, v.name_th, thd.house_no, thd.house_nearby, thd.house_code,
                    pf.name, thm.first_name, thm.last_name, thm.gender,
                    thm.identification_card, thm.age, thm.age_month,
                    opc.name, ed.name, rl.id, r.name, thm.is_self_reliance,
                    thm.is_normal, thm.is_disabled, thm.is_chronic_patient,
                    tgen.ref_house_data_id, s.unit_all, s.unit_passed, s.is_unit,
                    tgen.male, tgen.female, tgen.lgbti, s.passed, s.failed
                ORDER BY thd.house_no, rl.id
            ";

            // Create parameters once
            var parameters = new[]
            {
                new NpgsqlParameter("Year", Year),
                new NpgsqlParameter("ZoneID", ZoneId),
                new NpgsqlParameter("ProvinceID", ProvinceID),
                new NpgsqlParameter("DistrictID", DistrictID),
                new NpgsqlParameter("SubDistrictID", SubDistrictID),
                new NpgsqlParameter("VillageID", VillageID),
                new NpgsqlParameter("LGOID", LGO),
                new NpgsqlParameter("indicators", Indicators),
                new NpgsqlParameter("isHouseholder", IsHouseholder)
            };

            List<GetSecondReportDto> results = null;

            // Use switch expression for cleaner code
            var context = Year switch
            {
                2567 => _contextFactory.CreateDbContext(refRegionId),
                2568 => _contextFactory.CreateDb68Context(refRegionId),
                2569 => _contextFactory.CreateDb69Context(refRegionId),
                _ => throw new ArgumentException($"Unsupported year: {Year}")
            };

            using (context)
            {
                results = await context.Set<GetSecondReportDto>()
                    .FromSqlRaw(sqlQuery, parameters)
                    .ToListAsync();
            }

            return Ok(results);
        }
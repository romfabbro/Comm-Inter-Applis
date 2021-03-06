

DELETE FROM [SourceTarget_Table]
DELETE FROM [TableACopier]
DELETE FROM [SourceTarget]

INSERT INTO [dbo].[SourceTarget]
           ([SourceDatabase]
           ,[TargetDatabase]
		   ,[Instance])
		   SELECT 'Referentiel_EcoReleve.dbo.','EcoReleve_ECWP.dbo.',i.TIns_PK_ID
		   from securite.dbo.TInstance I where i.TIns_Database = 'EcoReleve_NARC' and TIns_ReadOnly=0
		   --UNION ALL 
		   --SELECT 'Referentiel_EcoReleve.dbo.','EcoReleve_NARC.dbo.',i.TIns_PK_ID
		   --from securite.dbo.TInstance I where i.TIns_Database = 'EcoReleve_NARC' and TIns_ReadOnly=0

/*** Observation propagation ***/
INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('ProtocoleType'
           ,'ID'
		   ,'Protocole_ERD'
		   ,'ID'
           ,1
		   ,0)
           

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('ObservationDynProp'
           ,'ID'
		   ,'Protocole_ERD'
		   ,'ID'
           ,2
		   ,0)
           

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('ProtocoleType_ObservationDynProp'
           ,'ID'
		   ,'Protocole_ERD'
		   ,'ID'
           ,3
		   ,0)
           


		   /*** Field ACtivity ***/ 
INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('fieldActivity'
           ,'ID'
		   ,'fieldActivity_ERD'
		   ,'ID'
           ,10
           ,0)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('FieldActivity_ProtocoleType'
           ,'ID'
		   ,'fieldActivity_ERD'
		   ,'ID'
		   ,11
		   ,0)

/*** SENSORS propagation ***/

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('SensorType'
           ,'ID'
		   ,'Sensor_ERD'
		   ,'ID'
           ,21
           ,0)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('SensorDynProp'
           ,'ID'
		   ,'Sensor_ERD'
		   ,'ID'
           ,22
           ,0)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('SensorType_SensorDynProp'
           ,'ID'
		   ,'Sensor_ERD'
		   ,'ID'
           ,23
           ,0)


		   /*** IndividualS propagation ***/

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('IndividualType'
           ,'ID'
		   ,'Individual_ERD'
		   ,'ID'
           ,31
           ,0)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('IndividualDynProp'
           ,'ID'
		   ,'Individual_ERD'
		   ,'ID'
           ,32
           ,0)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('IndividualType_IndividualDynProp'
           ,'ID'
		   ,'Individual_ERD'
		   ,'ID'
           ,33
           ,0)


		   /*** StationS propagation ***/

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('StationType'
           ,'ID'
		   ,'Station_ERD'
		   ,'ID'
           ,41
           ,0)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('StationDynProp'
           ,'ID'
		   ,'Station_ERD'
		   ,'ID'
           ,42
           ,0)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('StationType_StationDynProp'
           ,'ID'
		   ,'Station_ERD'
		   ,'ID'
           ,43
           ,0)


		   /**** Propagation Confi Grids & Forms ****/
INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('FrontModules'
           ,'ID'
		   ,'Modules_ERD'
		   ,'ID'
           ,51
           ,0)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('ModuleForms'
           ,'ID'
		   ,'Forms_ERD'
		   ,'ID'
           ,52
           ,1)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('ModuleGrids'
           ,'ID'
		   ,'Grids_ERD'
		   ,'ID'
           ,53
           ,1)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
		   ,[TypeObject],idObject
           ,[OrdreExecution]
           ,AllowDelete)
     VALUES
           ('TVersion'
           ,'TVer_PK_ID'
		   ,'Version_ERD'
		   ,'TVer_PK_ID'
           ,60
           ,0)

 INSERT INTO [dbo].[SourceTarget_Table]
           ([fk_SourceTarget]
           ,[fk_TableACopier])
		   SELECT s.ID,t.ID FROM TableACopier T 
		   JOIN SourceTarget S ON s.SourceDatabase='Referentiel_EcoReleve.dbo.'
		   WHErE t.[TypeObject] like '%ERD%'
		   
 		   



/****** Object:  StoredProcedure [dbo].[pr_ImportFormBuilder]    Script Date: 25/07/2016 10:29:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'pr_ImportFormBuilderOneProtocol')
DROP PROCEDURE pr_ImportFormBuilderOneProtocol
GO

CREATE PROCEDURE [dbo].[pr_ImportFormBuilderOneProtocol]
	@form_id int
AS
BEGIN

--DECLARE @form_id int SET @form_id = 72 ;

/********************************************************/
 ------- INSERTION DES NOUVEAU PROTOCOLETYPE -------

 INSERT INTO dbo.ProtocoleType  (Name,OriginalId,Status)

 SELECT FI.Name,'FormBuilder-' + convert(varchar,FI.ID),4 
 FROM FormBuilderFormsInfos FI
 WHERE NOT EXISTS (SELECT * FROM ProtocoleType PT 
					WHERE REPLACE(PT.OriginalId,'FormBuilder-','') = FI.ID)
 AND FI.ID = @form_id
 
-- Gestion de mise � jour des Noms des protocoles existants
UPDATE PT  SET Name= FI.Name
FROM ProtocoleType PT 
JOIN FormBuilderFormsInfos FI ON REPLACE(PT.OriginalId,'FormBuilder-','') = FI.ID
AND FI.ID = @form_id


/********************************************************/
------ Suppression des liens dynprop _ protocole -----
DELETE l 
FROM [ProtocoleType_ObservationDynProp] l
JOIN ProtocoleType PT ON l.FK_ProtocoleType = PT.ID
JOIN FormBuilderFormsInfos FI ON REPLACE(PT.OriginalId,'FormBuilder-','') = FI.ID
AND FI.ID = @form_id


/********************************************************/
 ------ INSERTION DES NOUVELLES DYN PROP --------
--DECLARE @form_id int SET @form_id = 72;

 INSERT INTO dbo.ObservationDynProp  (Name,TypeProp)
 --OUTPUT INSERTED.ID,INSERTED.NAME,INSERTED.TypeProp INTO @NewDynProp 
 SELECT DISTINCT FI.Name, CASE WHEN FBD.[DynPropType] IS NULL THEN 'String' ELSE FBD.[DynPropType] END--, fipp.*
 FROM FormBuilderInputInfos FI 
 LEFT JOIN [FormBuilderType_DynPropType] FBD ON FBD.[FBType] = FI.type 
			AND (
				[FBInputPropertyName] IS NULL 
				OR (FBD.IsEXISTS =1 AND EXISTS (	SELECT * FROM FormBuilderInputProperty FIP
						Where FIP.fk_input = Fi.ID 
						AND FIP.value = FBD.[FBInputPropertyValue] 
						AND FIP.name = FBD.[FBInputPropertyName]  
						)
					)
				OR (FBD.IsEXISTS =0 AND NOT EXISTS (	SELECT * FROM FormBuilderInputProperty FIP
						Where FIP.fk_input = Fi.ID 
						AND FIP.value = FBD.[FBInputPropertyValue] 
						AND FIP.name = FBD.[FBInputPropertyName]  
						)
					)
				)
--LEFT JOIN FormBuilderInputProperty fipp ON fipp.fk_input = fi.ID and fipp.name = 'format'
 WHERE EXISTS (SELECT * FROM ProtocoleType PT WHERE REPLACE(PT.OriginalId,'FormBuilder-','') = FI.fk_form)  
 AND NOT EXISTS (SELECT * FROM ObservationDynProp ODP WHERE ODP.Name = FI.name)
 AND FI.name NOT IN  (SELECT name FROM  sys.columns WHERE object_id = OBJECT_ID('dbo.Observation') )
 AND (FBD.BBEditor != 'ListOfNestedModel' or  FBD.BBEditor is null )
 AND FI.fk_form = @form_id

 select * 
 FROM FormBuilderInputProperty fip
 JOIN [FormBuilderType_DynPropType] fb on fip.name = fb.FBInputPropertyName and fip.value = fb.FBInputPropertyValue
 WHERE fip.fk_Input = 1248
/********************************************************/
---------- INSERTION DES NOUVELLES DYNPROP/TYPE --------
--DECLARE @form_id int SET @form_id = 72 ;

DECLARE @id_curProto int
INSERT INTO [ProtocoleType_ObservationDynProp]
           ([Required]
           ,[FK_ProtocoleType]
           ,[FK_ObservationDynProp]
		   ,Locked
			,LinkedTable
			,LinkedField
			,LinkedID
			,LinkSourceID)
SELECT FI.required, PT.ID,OD.ID,0
,CASE WHEN Fi.linkedFieldTable != '' AND fi.linkedFieldTable IS NOT NULL THEN FI.linkedFieldTable ELSE NULL END 
,CASE WHEN Fi.linkedField != '' THEN FI.linkedField ELSE NULL END 
,CASE WHEN Fi.linkedFieldIdentifyingColumn != '' THEN FI.linkedFieldIdentifyingColumn ELSE NULL END 
,CASE WHEN FI.linkedFieldTable IS NOT NULL AND Fi.linkedFieldTable != '' THEN 'FK_'+FI.linkedFieldTable
	ELSE NULL END --,fi.name

FROM FormBuilderInputInfos FI 
JOIN FormBuilderFormsInfos FF ON FI.fk_form = FF.ID AND FF.ID = @form_id
JOIN ObservationDynProp OD ON OD.Name = FI.Name
JOIN ProtocoleType PT ON REPLACE(PT.OriginalId,'FormBuilder-','') = FF.ID 
WHERE NOT EXISTS (select * from [ProtocoleType_ObservationDynProp] ODN 
				where ODN.FK_ProtocoleType = PT.ID 
				AND ODN.FK_ObservationDynProp = OD.ID) 

UPDATE FF
SET internalID = PT.ID
FROM FormBuilderFormsInfos FF 
JOIN ProtocoleType PT ON REPLACE(PT.OriginalId,'FormBuilder-','') = FF.ID
WHERE FF.ID = @form_id


SELECT @id_curProto = PT.ID FROM FormBuilderFormsInfos FF 
JOIN ProtocoleType PT ON REPLACE(PT.OriginalId,'FormBuilder-','') = FF.ID
WHERE FF.ID = @form_id

EXEC [Pr_FormBuilderUpdateConf_One_Form] @ObjectType = 'Protocole',@id_frontmodule=1,@proto_id = @id_curProto
 
END



GO



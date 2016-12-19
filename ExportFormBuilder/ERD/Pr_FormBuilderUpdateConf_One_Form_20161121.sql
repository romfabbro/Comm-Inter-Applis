USE [Referentiel_EcoReleve]
GO

/****** Object:  StoredProcedure [dbo].[Pr_FormBuilderUpdateConf_One_Form]    Script Date: 25/11/2016 09:22:52 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



ALTER PROCEDURE [dbo].[Pr_FormBuilderUpdateConf_One_Form]
(
@ObjectType varchar(255),
@id_frontmodule BIGINT,
@proto_id int
)
AS
	BEGIN

/********************************************************/
-- SUPPRESSION de la configuration

--DECLARE @ObjectType varchar(255) SET @ObjectType = 'Protocole'
--DECLARE @id_frontmodule BIGINT SET @id_frontmodule = 1
--DECLARE @proto_id int SET @proto_id=241

DELETE f 
FROM [ModuleForms] f
WHERE module_id= @id_frontmodule
AND TypeObj = @proto_id  --and (Locked = 0 or Locked is null) 


/********************************************************/
-- INSERTION DE LA CONFIGURATION
-- Faire un not exists
IF object_id('tempdb..#inserted') IS NOT NULL
			DROP TABLE #inserted
Create table #inserted (typeObj int,inputType varchar(250),subFromID varchar(250))


INSERT INTO [ModuleForms]
           ([module_id]
           ,[TypeObj]
           ,[Name]
           ,[Label]
           ,[Required]
           ,[FieldSizeEdit]
           ,[FieldSizeDisplay]
           ,[InputType]
           ,[editorClass]
           ,[FormRender]
           ,[FormOrder]
           ,[Legend]
           ,[Options]
           ,[Validators]
           ,[displayClass]
           ,[EditClass]
           ,[Status]
		   ,Locked
		   )
OUTPUT inserted.[TypeObj],inserted.inputType , inserted.Options into #inserted
SELECT  @id_frontmodule,
FF.internalID,
FI.name,
FI.labelFr,
FI.required,
	 FI.fieldSize,
	 FI.fieldSize
,CASE WHEN FBD.BBEditor is not null THEN FBD.BBEditor ELSE  FI.type END
,'form-control'
,2
,FI.[order],
FI.Legend,
CASE WHEN IPurl.value is NOT NULL THEN '{"source":"'+IPurl.value+'","minLength":'+IPlength.value+'}'
WHEN IPobjLab.value is not null THEN '{"usedLabel":"'+IPobjLab.value+'"}'
WHEN FI.type = 'ObjectPicker' AND IPobjT.Name = 'Non Identified Individual' THEN '{"withToggle":1}'
WHEN IPThes.value is not null then IPThes.value
WHEN FBD.FBInputPropertyValue Is NOT NULL THEN '{"'+FBD.FBInputPropertyName+'":"'+FBD.FBInputPropertyValue+'"}'
 ELSE CONVERT(varchar(250),PT.ID) END as Options,
NULL,
Fi.fieldClassDisplay,
FI.fieldClassEdit,
FI.curStatus,
0
--,fbd.*

FROM FormBuilderInputInfos FI JOIN FormBuilderFormsInfos FF ON FI.fk_form = FF.ID
LEFT JOIN FormBuilderType_DynPropType FBD ON FBD.[FBType] = FI.type 
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
LEFT JOIN FormBuilderInputProperty IPurl ON FI.ID =IPurl.fk_input AND IPurl.name = 'url'
LEFT JOIN FormBuilderInputProperty IPlength ON FI.ID =IPlength.fk_input AND IPlength.name = 'triggerlength'
LEFT JOIN FormBuilderInputProperty IPobjLab ON FI.ID =IPobjLab.fk_input AND IPobjLab.name = 'linkedLabel'
LEFT JOIN FormBuilderInputProperty IPThes ON FI.ID =IPThes.fk_input AND IPThes.name = 'defaultNode'
LEFT JOIN FormBuilderInputProperty IPsub ON FI.ID =IPsub.fk_input AND IPsub.name = 'childFormName'
LEFT JOIN FormBuilderInputProperty IPobjT ON FI.ID =IPobjT.fk_input AND IPobjT.name = 'objectType'
LEFT JOIN ProtocoleType pt ON pt.OriginalId='FormBuilder-'+convert(varchar(10),IPsub.value)
WHERE FF.internalID =  @proto_id AND 
FF.ObjectType = @ObjectType 



/* update status of child form in ProtocolType */
Update pt SET [Status] = 6
FROM ProtocoleType pt
JOIN #inserted f on pt.ID = f.subFromID and f.InputType = 'ListOfNestedModel'

/* Insert FK_ProtocoleType with defaults */ 
INSERT INTO [ModuleForms]
           ([module_id]
           ,[TypeObj]
           ,[Name]
           ,[Label]
           ,[Required]
           ,[FieldSizeEdit]
           ,[FieldSizeDisplay]
           ,[InputType]
           ,[editorClass]
           ,[FormRender]
           ,[FormOrder]
           ,[Legend]
           ,[Options]
           ,[Validators]
           ,[displayClass]
           ,[EditClass]
           ,[Status]
		   ,Locked
		   ,DefaultValue
		   )
SELECT @id_frontmodule
           ,i.subFromID
           ,'FK_ProtocoleType'
           ,'FK_ProtocoleType'
           ,0
           ,3
           ,3
           ,'Number'
           ,NULL
           ,0
           ,0
           ,''
           ,NULL
           ,NULL
           ,'hide'
           ,'hide'
           ,NULL
		   ,0
		   ,i.subFromID 
FROM  #inserted i 
WHERE i.inputType =  'ListOfNestedModel'
  
END







GO



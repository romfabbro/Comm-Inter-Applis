/****** Script de la commande SelectTopNRows à partir de SSMS  ******/

--DELETE FormBuilderType_DynPropType 
--WHERE FBType in ('DatePicker',
--'ThesaurusPicker',
--'ThesaurusPicker-DDL',
--'NumberPicker',
--'Radio')

--UPDATE FormBuilderType_DynPropType SET BBEditor = 'DateTimePickerEditor'
--WHERE BBEditor = 'DateTimePicker'


IF OBJECT_ID('tempdb..#tempConf') IS NOT NULL DROP TABLE #tempConf
GO

--------------------------------------------------- 


SELECT pt.Name as form,fl.FBType,CASE WHEN fl.FBType = 'number' then fl.IsEXISTS END as decimal
,CASE WHEN l.LinkedField IS NULL THEN '' ELSE l.LinkedField END as LinkedField
,CASE WHEN l.LinkSourceID IS NULL THEN '' ELSE l.LinkSourceID END  LinkSourceID
,CASE WHEN l.LinkedID IS NULL THEN '' ELSE l.LinkedID END LinkedID
,CASE WHEN l.LinkedTable IS NULL THEN '' ELSE l.LinkedTable END LinkedTable
---,l.LinkSourceID,l.LinkedID,l.LinkedTable
, f.*,dp.TypeProp
,ROW_NUMBER() OVER (PARTITION BY pt.ID ORDER BY f.FormOrder) as realOrder
into #tempConf
  FROM [dbo].[ModuleForms] f 
  JOIN ProtocoleType pt on pt.ID = f.TypeObj
  LEFT JOIN ObservationDynProp dp ON dp.Name = f.Name
  LEFT JOIN ProtocoleType_ObservationDynProp l on l.FK_ObservationDynProp = dp.ID and pt.ID = l.FK_ProtocoleType
  LEFT JOIN FormBuilderType_DynPropType fl on dp.TypeProp like '%'+fl.DynPropType+'%'  and fl.BBEditor = f.InputType --and fl.FBType not in ('numberpicker','ThesaurusPicker-DDL','ThesaurusPicker','Radio')
  WHERE module_id = 1 
  order by pt.Name

select * 
from #tempConf

ALTER TABLE #tempConf 
ADD newIdINput int, newIdform int;

UPDATE #tempConf Set Legend = ''
WHERE Legend IS nULL


INSERT INTO Formbuilder.dbo.Form (name,labelEn,labelFr,creationDate,modificationDate,curStatus,context,descriptionEn,descriptionFr,isTemplate,obsolete,originalID)
SELECT DISTINCT form,replace(form,'_',' '),replace(form,'_',' '), GETDATE(), GETDATE(),1,'ecoreleve',form+' form',form+' form',0,0,TypeObj
FROM #tempConf


UPDATE tc SET newIdForm = f.pk_Form
from #tempConf tc
JOIN Formbuilder.dbo.Form f ON f.name = tc.form



INSERT INTO Formbuilder.dbo.Input (
[fk_form]
      ,[name]
      ,[labelFr]
      ,[labelEn]
      ,[editMode]
      ,[fieldSize]
	  ,atBeginingOfLine
      ,[endOfLine]
      ,[startDate]
      ,[curStatus]
      ,[order]
      ,[type]
      ,[editorClass]
      ,[fieldClassEdit]
      ,[fieldClassDisplay]
      ,[linkedFieldTable]
      ,[linkedFieldIdentifyingColumn]
      ,[linkedField]
      ,[linkedFieldset])
select newIdForm,Name,Label,Label,CASE WHEN FormRender= 1 and Required = 0 then 5 WHEN FormRender = 2 and Required = 0 THEN 7 When FormRender= 2 And Required = 1 THEN 3 ELSE FormRender END
,FieldSizeDisplay,0,0, GETDATE(),1,realOrder-1,CASE WHEN FBType is not null THEN FBType ELSE InputType END,editorClass, EditClass,displayClass,LinkedTable,LinkedID,replace(LinkedField,'@Dyn:',''),Legend
from #tempConf

Update tc SET newIdInput  = i.pk_Input
FROM #tempConf tc
JOIN Formbuilder.dbo.Input i ON i.fk_form = tc.newIDForm and i.name = tc.Name



--------------- INSERT InputProperty For Thesaurus Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO

select newIdInput,CONVERT(Varchar(250),Options) as defaultNode ,  CONVERT(Varchar(250),th.TTop_Name) as fullPath, CONVERT(Varchar(250),Required) as required,  CONVERT(Varchar(250),'0') as iscollapsed ,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, CONVERT(Varchar(250),DefaultValue) as defaultValue
 ,  CONVERT(Varchar(250),'http://127.0.0.1/ThesaurusNew/api/thesaurus/fastInitForCompleteTree' ) as webServiceURL
INTO #tempInput
From #tempConf tc
JOIN THESAURUS.dbo.TTopic th ON th.TTop_PK_ID = Options
WHERE InputType = 'autocomptreeeditor'


INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, value,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL','decimal') THEN 'Boolean'  WHEN Name in ('triggerlength','precision') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( value FOR name IN 
      (defaultNode, iscollapsed, atBeginingOfLine,readonly,fullpath,required,defaultValue,webServiceURL)
)AS unpvt;



--------------- INSERT InputProperty For Autocomplete Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO

UPDATE tc SET Options = Replace(Options,' ','')
From #tempConf tc
WHERE InputType = 'autocompleteeditor'


select newIdInput,CONVERT(Varchar(250),SUBSTRING(
        Options
        ,CHARINDEX('"source":"', Options) + LEN('"source":"')
        ,CHARINDEX('"', Options, CHARINDEX('"source":"', Options) + LEN('"source":"')) - CHARINDEX('"source":"',Options) - LEN('"source":"')
    ) ) as url
,CONVERT(Varchar(250),SUBSTRING(
        Options
        ,CHARINDEX('"minLength":', Options) + LEN('"minLength":')
        ,CHARINDEX(',', Options, CHARINDEX('"minLength":', Options) + LEN('"minLength":')) - CHARINDEX('"minLength":',Options) - LEN('"minLength":')
    ) )as triggerlength
--,CONVERT(Varchar(250),SUBSTRING(
--        Options
--        ,CHARINDEX('"value":"', Options) + LEN('"value":"')
--        ,CHARINDEX('"', Options, CHARINDEX('"value":"', Options) + LEN('"value":"')) - CHARINDEX('"value":"',Options) - LEN('"value":"')
--    ))as value

--,CONVERT(Varchar(250),SUBSTRING(
--        Options
--        ,CHARINDEX('"label":"', Options) + LEN('"label":"')
--        ,CHARINDEX('"', Options, CHARINDEX('"label":"', Options) + LEN('"label":"')) - CHARINDEX('"label":"',Options) - LEN('"label":"')
--    )) as label
--,CONVERT(Varchar(250),SUBSTRING(
--        Options
--        ,CHARINDEX('"object":"', Options) + LEN('"object":"')
--        ,CHARINDEX('"', Options, CHARINDEX('"object":"', Options) + LEN('"object":"')) - CHARINDEX('"object":"',Options) - LEN('"object":"')
--    )) as object
--,Options
,CONVERT(Varchar(250),Required) as required,  CONVERT(Varchar(250),'0') as iscollapsed ,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, 
  CONVERT(Varchar(250),'Entrez une valeur pour voir la liste d''autocomplétion') as help,
   CONVERT(Varchar(250),'0') as isSQL ,
 Case WHEN DefaultValue is null THEN  CONVERT(Varchar(250),'') else CONVERT(Varchar(250),DefaultValue) END as defaultValue
INTO #tempInput
From #tempConf tc
WHERE InputType = 'autocompleteeditor'


INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, valueee,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL') THEN 'Boolean'  WHEN Name in ('triggerlength') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( valueee FOR name IN 
      (iscollapsed, atBeginingOfLine,readonly,required,defaultValue /**,label,value,object**/,triggerlength,url)
)AS unpvt;





--------------- INSERT InputProperty For Date Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO

select newIdInput,CONVERT(Varchar(250),0) as isDefaultSQL , CONVERT(Varchar(250),Required) as required,  CONVERT(Varchar(250),'0') as iscollapsed ,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, CONVERT(Varchar(250),DefaultValue) as defaultValue
 , Case WHEN tc.TypeProp = 'Date Only' THEN CONVERT(varchar(250),'DD/MM/YYYY')
		WHEN tc.TypeProp = 'Time' THEN CONVERT(varchar(250),'HH:mm:ss')
		ELSE CONVERT(varchar(250),'DD/MM/YYYY HH:mm:ss') END as format
INTO #tempInput
From #tempConf tc
WHERE InputType = 'datetimepickereditor'


INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, value,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL') THEN 'Boolean'  WHEN Name in ('triggerlength') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( value FOR name IN 
      (format, iscollapsed, atBeginingOfLine,readonly,required,defaultValue,isDefaultSQL)
)AS unpvt;


--------------- INSERT InputProperty For Object picker Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO

UPDATE f SET Options = ''
FROM #tempConf f
WHERE InputType = 'ObjectPicker' and (Options is null or options = '0' )

select newIdInput,CONVERT(Varchar(250),3) as triggerAutocomplete , CONVERT(Varchar(250),Required) as required,  CONVERT(Varchar(250),'0') as iscollapsed ,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, CONVERT(Varchar(250),DefaultValue) as defaultValue
 ,CASE WHEN Options != '' THEN CONVERT(Varchar(250),SUBSTRING(
        Options
        ,CHARINDEX('"usedLabel":"', Options) + LEN('"usedLabel":"')
        ,CHARINDEX('"', Options, CHARINDEX('"usedLabel":"', Options) + LEN('"usedLabel":"')) - CHARINDEX('"usedLabel":"',Options) - LEN('"usedLabel":"')
    ) ) ELSE '' END as linkedLabel
	
	, CASE WHEN Label like '%Non%' AND Name = 'FK_Individual' THEN CONVERT(varchar(250),'Non Identified Individual')
		ELSE CONVERT(varchar(250),replace(Name,'FK_','')) END as objectType
	, CONVERT(varchar(250),'autocomplete/'+replace(Name,'FK_','')) as wsUrl
INTO #tempInput
From #tempConf tc
WHERE InputType = 'ObjectPicker'


INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, value,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL') THEN 'Boolean'  WHEN Name in ('triggerlength') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( value FOR name IN 
      (objectType, iscollapsed, atBeginingOfLine,readonly,required,defaultValue,triggerAutocomplete,wsUrl)
)AS unpvt;

--------------- INSERT InputProperty For NonID Object picker Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO


select newIdInput,CONVERT(Varchar(250),3) as triggerAutocomplete , CONVERT(Varchar(250),Required) as required,  CONVERT(Varchar(250),'0') as iscollapsed ,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, CONVERT(Varchar(250),DefaultValue) as defaultValue
 --,CASE WHEN Options != '' THEN CONVERT(Varchar(250),SUBSTRING(
 --       Options
 --       ,CHARINDEX('"usedLabel":"', Options) + LEN('"usedLabel":"')
 --       ,CHARINDEX('"', Options, CHARINDEX('"usedLabel":"', Options) + LEN('"usedLabel":"')) - CHARINDEX('"usedLabel":"',Options) - LEN('"usedLabel":"')
 --   ) ) ELSE '' END as linkedLabel
 , convert(varchar(250),'') as linkedLabel
	
	, convert(varchar(250),'Non Identified Individual') as objectType, CONVERT(varchar(250),'autocomplete/'+replace(Name,'FK_','')) as wsUrl
	,options
INTO #tempInput
From #tempConf tc
WHERE InputType = 'nonidpicker'

UPDATE i SET type = 'ObjectPicker'
FROM Formbuilder.dbo.Input i
WHERE type = 'nonidpicker' 

INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, value,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL') THEN 'Boolean'  WHEN Name in ('triggerlength') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( value FOR name IN 
      (objectType, iscollapsed, atBeginingOfLine,readonly,required,defaultValue,triggerAutocomplete,wsUrl)
)AS unpvt;


--------------- INSERT InputProperty For Number Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO


select newIdInput,CASE WHEN decimal is null THEN CONVERT(Varchar(250),0) ELSE CONVERT(Varchar(250),decimal) END as decimal , CONVERT(Varchar(250),Required) as required,  CONVERT(Varchar(250),'0') as iscollapsed ,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, CONVERT(Varchar(250),DefaultValue) as defaultValue
  ,CONVERT(Varchar(250),'1') as precision
  , CONVERT(Varchar(250),'') as maxValue
  ,CONVERT(Varchar(250),'') as minValue
  --,CONVERT(Varchar(250),SUBSTRING(
  --      Validators
  --      ,CHARINDEX('"value":', Validators) + LEN('"value":')
  --      ,CHARINDEX('"', Validators, CHARINDEX('"value":', Validators) + LEN('"value":')) - CHARINDEX('"value":',Options) - LEN('"value":')
  --  ) )as triggerlength
  ,CONVERT(Varchar(250),'') as unity
INTO #tempInput
From #tempConf tc
WHERE InputType = 'Number'

/**** TO DO ******
SELECT 
--CONVERT(Varchar(250),SUBSTRING(
--        Validators
      CHARINDEX('"value"', Validators) + LEN('"value"')
        ,CHARINDEX('', Validators, CHARINDEX('"value"', Validators) + LEN('"value"')) - CHARINDEX('"value":',Options) - LEN('"value"')
     as triggerlength
From #tempConf tc
WHERE InputType = 'Number' and label = 'muscle'
***/

INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, value,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL','decimal') THEN 'Boolean'  WHEN Name in ('triggerlength','precision') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( value FOR name IN 
      (iscollapsed, atBeginingOfLine,readonly,required,defaultValue,decimal,maxValue,minValue,unity,precision)
)AS unpvt;

--------------- INSERT InputProperty For text Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO


select newIdInput,CONVERT(Varchar(250),0) as isDefaultSQL,CONVERT(Varchar(250),'') as help ,CONVERT(Varchar(250),'0;255') as valuesize  , CONVERT(Varchar(250),Required) as required,  CONVERT(Varchar(250),'0') as iscollapsed ,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, CONVERT(Varchar(250),DefaultValue) as defaultValue

INTO #tempInput
From #tempConf tc
WHERE InputType in ('text','TextArea')


INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, value,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL','decimal') THEN 'Boolean'  WHEN Name in ('triggerlength','precision') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( value FOR name IN 
      (iscollapsed, atBeginingOfLine,readonly,required,defaultValue,isDefaultSQL,help,valuesize)
)AS unpvt;



/********TO DO ***/
--------------- INSERT InputProperty For Select Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO


select newIdInput,CONVERT(Varchar(250),0) as isDefaultSQL,CONVERT(Varchar(250),'') as help ,CONVERT(Varchar(250),'0;255') as valuesize  , CONVERT(Varchar(250),Required) as required,  CONVERT(Varchar(250),'0') as iscollapsed ,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, CONVERT(Varchar(250),DefaultValue) as defaultValue

INTO #tempInput
From #tempConf tc
WHERE InputType ='select'


INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, value,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL','decimal') THEN 'Boolean'  WHEN Name in ('triggerlength','precision') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( value FOR name IN 
      (iscollapsed, atBeginingOfLine,readonly,required,defaultValue,isDefaultSQL,help,valuesize)
)AS unpvt;


--------------- INSERT InputProperty For subForm Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO


select newIdInput,CONVERT(Varchar(250),'') as help , CONVERT(Varchar(250),Required) as required,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, CONVERT(Varchar(250),DefaultValue) as defaultValue
 ,CONVERT(Varchar(250),(SELECT pk_Form FROM formbuilder.dbo.Form WHERE Name = tc.name)) as childForm,CONVERT(Varchar(250),tc.Name )as childFormName, CONVERT(Varchar(250),'0') as minimumAppearance
INTO #tempInput
From #tempConf tc
WHERE InputType ='ListOfNestedModel'


INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, value,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL','decimal') THEN 'Boolean'  WHEN Name in ('triggerlength','precision','minimumAppearance') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( value FOR name IN 
      ( atBeginingOfLine,readonly,required,defaultValue,help,childForm,childFormName,minimumAppearance)
)AS unpvt;

UPDATE i SET type = 'ChildForm'
FROM Formbuilder.dbo.Input i
WHERE type = 'ListOfNestedModel' 

/*** TODO ****/
--------------- INSERT InputProperty For subFormGRID Input --------------------------------

IF OBJECT_ID('tempdb..#tempInput') IS NOT NULL DROP TABLE #tempInput
GO


select newIdInput, CONVERT(Varchar(250),Required) as required,
 CONVERT(Varchar(250),'0') as atBeginingOfLine, CONVERT(Varchar(250),CASE WHEN tc.FormRender = 1 THEN '1' ELSE '0' END )as readonly, CONVERT(Varchar(250),DefaultValue) as defaultValue
 , CONVERT(Varchar(250),
 
 (select pk_Form FROm Formbuilder.dbo.form WHERE Name = 
( select Name FROM ProtocoleType WHERE ID = 
SUBSTRING(
        Options
        ,CHARINDEX('"protocoleType":', Options) + LEN('"protocoleType":')
        ,CHARINDEX(',', Options, CHARINDEX('"protocoleType":', Options) + LEN('"protocoleType":')) - CHARINDEX('"protocoleType":',Options) - LEN('"protocoleType":')
    ))
	)
	  ) as childForm

 ,  CONVERT(Varchar(250),SUBSTRING(
        Options
        ,CHARINDEX('"nbFixedCol":', Options) + LEN('"nbFixedCol":')
        ,CHARINDEX(',', Options, CHARINDEX('"nbFixedCol":', Options) + LEN('"nbFixedCol":')) - CHARINDEX('"nbFixedCol":',Options) - LEN('"nbFixedCol":')
    ) )  as nbFixedCol
 ,CONVERT(Varchar(250),SUBSTRING(
        Options
        ,CHARINDEX('"showLines":', Options) + LEN('"showLines":')
        ,CHARINDEX('}', Options, CHARINDEX('"showLines":', Options) + LEN('"showLines":')) - CHARINDEX('"showLines":',Options) - LEN('"showLines":')
    ) ) as showLines
 , CONVERT(Varchar(250),SUBSTRING(
        Options
        ,CHARINDEX('"delFirst":', Options) + LEN('"delFirst":')
        ,CHARINDEX(',', Options, CHARINDEX('"delFirst":', Options) + LEN('"delFirst":')) - CHARINDEX('"delFirst":',Options) - LEN('"delFirst":')
    ) ) as delFirst
INTO #tempInput
From #tempConf tc
WHERE InputType ='GridFormEditor'


INSERT INTO Formbuilder.dbo.InputProperty ([fk_Input]
      ,[name]
      ,[value]
      ,[creationDate]
      ,[valueType])
SELECT newIdInput,name, value,GETDATE(),Case WHEN Name in ('iscollapsed', 'atBeginingOfLine','readonly','required','isDefaultSQL','decimal','delFirst','showLines','nbFixedCol') THEN 'Boolean'  WHEN Name in ('triggerlength','precision','minimumAppearance') THEN 'Number'ELSE 'String' END
FROM
(SELECT * FROM #tempInput ) thP 
UNPIVOT
   ( value FOR name IN 
      ( atBeginingOfLine,readonly,required,defaultValue,nbFixedCol,childForm,showLines,delFirst)
)AS unpvt;

UPDATE i SET type = 'SubFormGrid'
FROM Formbuilder.dbo.Input i
WHERE type = 'GridFormEditor' 


UPDATE pt SET OriginalId = 'FormBuilder-'+convert(varchar(12),FF.pk_Form)
  FROM [ProtocoleType] pt
  JOIN Formbuilder.dbo.Form ff on ff.name = pt.Name 

//-------------------------------------------------------------------
/*/{Protheus.doc}

@description    Efetua a conversao para csv da primeira planilha passada como parametro
@author         @walterfcarvalho
@since          16/08/2020
@version        1.00
/*/
//-------------------------------------------------------------------

#INCLUDE 'PROTHEUS.CH'
#include "shell.ch"
#INCLUDE 'TOTVS.CH'


User function xlsxToArr(cArq, cIdPlan)
    Local oProcess  := nil
    Local aRes      := nil
    Local lEnd      := .F.
    
    Default cIdPlan := "1"
    Default cArq    := ""
    
	oProcess := MsNewProcess():New({|lEnd| aRes:= Converter(cArq, cIdPlan, @oProcess, @lEnd)  },"Extraindo dados da planilha XLSX","Efetuando a leitura do arquivo xlsx...", .T.)

	oProcess:Activate()

Return aRes

Static Function Converter(cArq, cIdPlan, oProcess, lEnd)
    Local nPassos   := 0
    Local nReg      := 0    
    Local nShell    := 0
    Local cMsgHead  := "xlsxToArr()"
    Local cDirIni   := StrTran(GetTempPath(), "AppData\Local\Temp\", "")
    Local aRes      := {}
    Local nHandle   := 0
    Local cExe      := "xlsxToCsv.exe"
    Local cArqCsv   := ""
    Local cArqTmp   := ""


    // Se nao enviar cArq, abre dialogo para escolher o arquivo
    If Empty(cArq) = .T.
        cArq := cGetFile( "Arquivos Excel|*.xls", "Selecione o arquivo:",  1, cDirIni, .F., GETF_LOCALHARD, .F., .T. )

        If Empty(cArq)
        ApMsgStop("Importacao Cancelada:", cMsgHead)
            Return aRes
        EndIf
    EndIf

    // Gere o nome do arquivo CSV temporario
    cArqCsv := SubStr(cArq, 1, Rat(".", cArq) ) + "csv"
    cArqTmp := SubStr(cArq, 1, Rat(".", cArq) ) + "tmp"

    // Valida se o arquivo informado existe
    If File(cArq,/*nWhere*/,.T.) = .F.
        ApMsgStop("Arquivo n�o encontrado:" + cArq, cMsgHead)
        Return aRes
    EndIf

    oProcess:SetRegua1(4)
    oProcess:SetRegua2(2)
    
    oProcess:IncRegua1("1/4 Baixar xlsxTocsv.exe")
    oProcess:IncRegua2("")

    // Pega do servidor o arquivo que vai converter o xlsx  para csv
    If File( GetClientDir() + cExe ) = .F.
        If CpyS2T("\system\xlsxtocsv.exe", GetClientDir(), .F., .F.) = .F.
            ApMsgStop('N�o foi poss�vel baixar o conversor do servidor, em "\system\"' + cExe, cMsgHead)
            Return aRes
        EndIf

    EndIf

    oProcess:IncRegua1("2/4 Arq CSV temporario")
    oProcess:SetRegua2(20)

    nShell := Shellexecute('open', '"' + GetClientDir() + cExe + '"', '"' + Alltrim(cArq) + '" "' + cIdPlan + '" ' , GetClientDir(), 0)

    While File(cArqCsv) = .F.
        nPassos += 1

        if lEnd = .T.    //VERIFICAR SE N�O CLICOU NO BOTAO CANCELAR
            ApMsgStop("Processo cancelado pelo usu�rio." + cArq, cMsgHead)
            Return aRes
        EndIf

        If nPassos = 50
            ApMsgStop("A convers�o excedeu o tempo limite para o arquivo" + cArq, cMsgHead)
            Return aRes
        EndIf

        oProcess:IncRegua2("Convertendo arquivo...")

        If nShell = -1 .Or. nShell = 2
            ApMsgStop("N�o foi poss�vel efetuar a convers�o do arquivo." + cArq, cMsgHead)
            Return aRes
        Else    
            Sleep(1000)
        EndIf 

    EndDo

    nHandle := FT_FUse(cArqCsv)
    If nHandle < 0
        ApMsgStop("N�o foi poss�vel ler o arquivo CSV." + cArq, cMsgHead)
        Return aRes
    EndIf

    if lEnd = .T.   //VERIFICAR SE N�O CLICOU NO BOTAO CANCELAR
        ApMsgStop("Processo cancelado pelo usu�rio." + cArq, cMsgHead)
        Return aRes
    EndIf


    oProcess:IncRegua1("3/4 Ler Arquivo CSV")
    oProcess:SetRegua2(FT_FLastRec())

    // Posiciona na primeria linha
    FT_FgoTop() 

    While !Ft_Feof()

        if lEnd = .T.    //VERIFICAR SE N�O CLICOU NO BOTAO CANCELAR
            ApMsgStop("Processo cancelado pelo usu�rio." + cArq, cMsgHead)
            Return {}
        EndIf

        nReg += 1
        oProcess:IncRegua2("Lendo registro " + CvalToChar(nReg) + " de " + cValToCHar(FT_FLastRec()) )

        cLinha  := FT_FReadLn()

        If Empty(cLinha) = .F.    
            Aadd( aRes, Separa(cLinha, ",", .F.))
        EndIf            

        Ft_Fskip()
    EndDo


    oProcess:IncRegua1("4/4 Remove temporarios")
    oProcess:SetRegua2(1)
    oProcess:IncRegua2("")

    // Fecha o Arquivo
    Ft_Fuse()

    // remove o arquivo csv
    FErase(cArqCsv)
    FErase(cArqTmp)

Return aRes

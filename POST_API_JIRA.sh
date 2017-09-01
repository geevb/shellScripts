#!/bin/bash
#########################################################
#                                                       #
# Crição automática de issues no JIRA, v1.0.0           #
# Autor: Getúlio V. Benincá, 2017                       #
#                                                       #
#########################################################

# Campos obrigatórios da API do JIRA.
readonly PROJETO=""
readonly CHAVE_PROJETO=""

readonly URL_JIRA = ""
readonly URL=''
readonly URL_SEM_BARRA=""
readonly LOCAL_HOST='http\:\/\/localhost\:8080'

# Parâmetros p/ o SED
readonly PONTO="\."
readonly ESPACO="\ "

#Resposta da API do JIRA após o POST.
respPost=""

# Usuário e Senha de rede da pessoa criando a issue.
usuario=""
senha=""

# URLs do Link do JIRA; Param = URL passada durante a execuçã do script; Final = URL tratada pelo SED que será linkada na issue do JIRA.
urlParam=""
urlFinal=""

# Título final que a issue vai ter
titulo=""


function mostrar_aviso() {
	echo -e "${RED}Se a página que está tentando inserir não tiver sido commitada, o link da página na issue não será válido até o commit ser efetuado.${NC} \n"
	echo -e "${RED}Por favor commite assim que possível${NC}\n"
}

function perguntar_deseja_commitar() {
	echo -e "Alterações finalizadas? Deseja commitar antes de criar a issue ao JIRA?"
	perguntar_sim_nao
	local x=$?
	if [ "${x}" = 1 ]; then
		return 1
	else
		return 0
	fi
}

function perguntar_sim_nao() {
	# Retorna 1 p/ SIM,
	# 0 p/ NÂO.
	local loop=true
	while [ "${loop}" = "true" ]
	do
	read -e -p "(S/N)? " resposta
	case $resposta in 
	   y|Y|Yes|YEs|YES|s|S|Sim|SIm|SIM ) loop=false; return 1;;
	   n|N|no|No|nao|Nao|NAo|NAO|não|Não|NÃo|NÃO ) loop=false; return 0;;
	   *) echo -e " ${RED}Resposta invalida${NC}, por favor digite novamente!\n";;
	esac
	done
}

function verificar_alteracoes() {
	# Verificar com GIT alterações na máquina local
	local mensagemStatus=$(git status | grep -E -o 'nothing to commit, working directory clean')
  if [ "$mensagemStatus" = "nothing to commit, working directory clean" ]; then
    return 0
  else
    return 1
  fi
}

#TODO Criar Título p/ issue
function efetuar_post_jira_api() {
	echo -e "\n${GREEN}Criando issue...${NC}\n"
	local descricao="Issue criada automaticamente. Para mais detalhes da demanda, acessar: ${urlFinal}"
	local tituloFinal="Deve Ser Possível ${titulo}"
	respPost=$(curl -u "${usuario}:${senha}" -X POST -d "{
    \"fields\": {
       \"project\":
       { 
        \"name\": \"${PROJETO}\",
        \"key\": \"${CHAVE_PROJETO}\",
        \"id\": \"10010\"
       },
       \"summary\": \"${tituloFinal}\",
       \"description\": \"${descricao}\",
       \"issuetype\": {
          \"name\": \"Story (Scrum)\"
       },
    \"assignee\": {
      \"name\": \"${usuario}\",
      \"key\": \"${usuario}\"      
    }
  }
}" -H "Content-Type: application/json" ${URL_JIRA}/rest/api/2/issue/)
	local unauthorized=$(echo -e "${respPost}" | grep -m1 -o "Unauthorized")
	if [ "${unauthorized}" = "Unauthorized" ]; then
		echo -e "${RED}Usuário ou Senha inválidos! \nPor favor reinsira-os.\n${NC}"
		perguntar_usuario
	else
		tratar_resposta_post
	fi
}

function tratar_resposta_post() {
	echo "${respPost}"
	read
	local x=$(echo "${respPost}" | grep -E -o '([A-Z]{2}-[0-9]{4})')
	echo -e "Issue ${x} criada com sucesso."
}

function criar_issue_jira() {
	perguntar_url
	# Em seguida de Perguntar Usuario é enviaro o POST, caso a resposta seja inválida, voltará p/ a Pergunta de usuário
	perguntar_usuario
}

function perguntar_usuario() {
	read -e -p "Por favor digite seu usuário: " usuario
	echo -e "Voce inseriu: ${GREEN}${usuario}${NC}\n"
	unset PASSWORD
	unset CHARCOUNT
	local PROMPT="Por favor digite sua senha: "
	stty -echo
	local CHARCOUNT=0
	while IFS= read -p "$PROMPT" -r -s -n 1 CHAR
	do
    # Inserir senha e pressionar enter
    if [[ $CHAR == $'\0' ]] ; then
        break
    fi
    # Tratamento p/ remover caracteres e * com Backspace
    if [[ $CHAR == $'\177' ]] ; then
        if [ $CHARCOUNT -gt 0 ] ; then
            CHARCOUNT=$((CHARCOUNT-1))
            PROMPT=$'\b \b'
            PASSWORD="${PASSWORD%?}"
        else
            PROMPT=''
        fi
    else
        CHARCOUNT=$((CHARCOUNT+1))
        PROMPT='*'
        PASSWORD+="$CHAR"
    fi
	done
	stty echo
	senha="${PASSWORD}"	
	efetuar_post_jira_api
}

function perguntar_url(){
	local loop=true
	local urlResp=""
	while [ "$loop" = "true" ]
	do
	read -e -p "Por favor cole a URL completa da página a ser enviada ao JIRA e então pressione ENTER: " urlResp
	urlParam="${urlResp}"
	echo -e "\nA URL inserida foi: ${GREEN}${urlParam}${NC}"
	read -e -p "Está correta? (S/N) " resposta
	case $resposta in 
	   y|Y|Yes|YEs|YES|s|S|Sim|SIm|SIM ) 
		if [ "${urlParam}" = "" ]; then 
			echo -e "\n${RED}URL Inválida!${NC}\n"
		else
			echo -e "${GREEN}Iniciando criação da issue no JIRA${NC}"
			loop=false
		fi;;
	   n|N|no|No|nao|Nao|NAo|NAO|não|Não|NÃo|NÃO ) echo -e "Por favor, insira a URL correta.\n";;
	   *) echo -e " ${RED}Resposta invalida${NC}, por favor reinsira a URL e confirme novamente!\n";;
	esac
	done

	local z=$(echo "${urlResp}" | grep -o "${URL_SEM_BARRA}")

	# Pega o URL passado por parametro, retira os pontos e coloca espaço, pega a última palavra do link, remove Dsp, separa as palavras juntas.
	local tituloNovo=$(echo "${urlResp}" | sed -r "s/${PONTO}/${ESPACO}/g" | awk 'NF>1{print $NF}' | sed -r "s/Dsp/""/g" | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g')
	#local ultimaPalavraTitulo=$(echo ${tituloNovo} | awk 'NF>1{print $NF}' )
	#local tituloSemDsp=$(echo ${ultimaPalavraTitulo} | sed -r "s/Dsp/""/g")
	#local tituloSemEspaco=$(echo "${tituloSemDsp}" | sed 's/\([a-z]\)\([A-Z]\)/\1 \2/g')
	titulo="${tituloNovo}"
	if [ "${z}" = "${URL_SEM_BARRA}" ]; then
		urlFinal="${urlParam}"
	else	
	# Substitui o LOCAL_HOST:8080 pelo URL
		local y=$(echo "${urlParam}" | sed -r "s/${LOCAL_HOST}/${URL}/g")
		urlFinal="${y}"
		echo -e "URL FINAL: ${urlFinal}"
		read
	fi
}
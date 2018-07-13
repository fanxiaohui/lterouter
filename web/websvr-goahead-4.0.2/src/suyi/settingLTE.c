#include"suyi_common.h"
#define ApnConf "/opt/config/ApnConfig"

int imsi_read(int fd,char *IMSI)
{/*{{{*/
	char rbuff[4096] = {'\0'};
	char* ptr = rbuff;
	int ret=0;
	while (1) {
		ret = read(fd, ptr, 0x01);
		if (1 == ret) {
			if ('\n' != *ptr) {
				ptr++;
			}
			else {
				printf("%s",rbuff);
				if(strlen(rbuff) < 15)
					return -1;
				else
					strcpy(IMSI,rbuff);
				return 0;
			}
		}
		else {
			syslog(LOG_DEBUG,"at_read_err:\n");
			return -1;
		}
	}
	syslog(LOG_DEBUG,"read exit\n");
}/*}}}*/

void queryIMSI(Webs *wp)
{
	int fd = 0, i = 0,ret = 0;
	char IMSI[64] = {'\0'};
	printf("\n********%s********\n",__FUNCTION__);
	websSetStatus(wp, 200);
	websWriteHeaders(wp, -1, 0);//参数二需要未-1,否则前端收不到数据
	websWriteEndHeaders(wp);
	
	for(i=0;i<3;i++){
		fd = openDev(SerPort);
		if(fd > 0)
			break;
		else
			printf("IMIS openDev Failed!\n");
	}

	tcflush(fd,TCIOFLUSH);
	at_send(fd,"at+cimi\r\n");
	for(i=0;i<3;i++){
		ret = imsi_read(fd,IMSI);
		if(ret >= 0)
			break;
		else
			printf("IMIS read Failed!\n");
	}
	printf("IMSI:%s",IMSI);
    websWrite(wp,("%s"),IMSI);
	websDone(wp);
	return;
}

void settingAPN(Webs *wp)
{
	char *apn;
	printf("\n********%s********\n",__FUNCTION__);
	websSetStatus(wp, 200);
	websWriteHeaders(wp, -1, 0);//参数二需要未-1,否则前端收不到数据
	websWriteEndHeaders(wp);

	apn = websGetVar(wp,("apn"),("jk"));
	printf("settingAPN apn=%s\n",apn);

	setConfig("apn",apn,ApnConf);

    websWrite(wp,("重启后生效"));
	websDone(wp);
	return;
}

void queryAPN(Webs *wp)
{
        char buff[64] = {'\0'};//读取文件缓存

	printf("\n********%s********\n",__FUNCTION__);
	websSetStatus(wp, 200);
	websWriteHeaders(wp, -1, 0);//参数二需要未-1,否则前端收不到数据
	websWriteEndHeaders(wp);
        getConfig("apn",buff,ApnConf);
        printf("apn = %s\n", buff);

        websWrite(wp,("%s"),buff);

        websDone(wp);
        return;
}

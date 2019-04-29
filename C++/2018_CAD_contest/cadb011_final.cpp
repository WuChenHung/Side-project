#include<iostream>
#include<fstream> 
#include<sstream>
#include<queue>
#include<string>
#include<vector>
#include <map>
#include<string.h>
#include <math.h>
using namespace std;

//kiss structure
struct Node{
string input;
string output;
bool prime;
};

//In put out put of water_mark
struct IONODE{
    public:
        string inbin;
        string outbin;  
};
// index
vector<IONODE> io_list1;
vector<IONODE> io_list2;
vector<IONODE> io_list3;
vector<int> ans1;//第一組答案在哪些state上 
vector<int> ans2;//第二組答案在哪些state上
vector<int> ans3;//第三組答案在哪些state上  
vector<vector<string> > graph_o;//紀錄原圖 
vector<vector<string> > graph_n;//紀錄新增的部分 
vector<string> finalans;
stringstream ss;
vector<vector<vector <Node> > >graph;
int inputnum,outputnum,termnum,statenum,startnum,totalcost;

//functions
int BintoDec(string word);

void Quine_McCluskey(vector<Node>& inputdata,vector<Node>& anslist,int& inputnum);

void recursive_call(string input,vector<vector<int> >& temparray,map<int,int>& mapvalue,int rownumber);

string DectoBin(int dec);

vector<vector<vector <Node> > >&  buildgraph(ifstream& infile);

void buildedge(string input,string from,string to,string output);

void viewgraph();

int checkcompletegraph();

const char* hex_char_to_bin(char c);

void cut_data(FILE* fp,int in , int out,vector<IONODE>& io_list1);

void findexistedge(vector<int>& ans,vector<IONODE>& io_list);

void newedge(vector<int>& ans,vector<IONODE>& io_list);

void processgraph_o(ifstream& infile);

void viewans(vector<int>& ans,vector<IONODE>& io_list);

string BFS(int sourcenum,int& length,vector<int>& ans);

string tostring(int x);

string DectoHex(int x);//convert decimal to Hex
void connectnewvertex();
/////////////////////////////////////////////////////
int main(int argc, char* argv[])
{
	// Read kiss file
	stringstream ss;
	//cout<<argv[1]<<" "<<argv[2];
	ifstream infile(argv[2]);
	ifstream infile_o(argv[2]);//用以儲存原圖 以方便輸出 否則不易將input 合併回含有dont care項再輸出 
	ofstream fgraph(argv[4]),fmd5_1e("md5_1.env"),fmd5_1i("md5_1.ini"),fmd5_2e("md5_2.env"),fmd5_2i("md5_2.ini"),fmd5_3e("md5_3.env"),fmd5_3i("md5_3.ini");
/*	ifstream infile("t2_1.kiss");
	ifstream infile_o("t2_1.kiss");//用以儲存原圖 以方便輸出 否則不易將input 合併回含有dont care項再輸出 
	ofstream fgraph("ofsm.kiss"),fmd5_1e("md5_1.env"),fmd5_1i("md5_1.ini"),fmd5_2e("md5_2.env"),fmd5_2i("md5_2.ini"),fmd5_3e("md5_3.env"),fmd5_3i("md5_3.ini"); */
	string word;

	totalcost=0;
	infile>>word>>inputnum>>word>>outputnum>>word>>termnum>>word>>statenum>>word>>word;
	word=word.assign(word,1,word.size());

	ss<<word;
	ss>>startnum;
	totalcost=0;
	//cout<<endl<<".i "<<inputnum<<endl<<".o "<<outputnum<<endl<<".p "<<endl<<".s "<<statenum<<endl<<".r S"<<startnum<<endl;
	int x=statenum;
	graph=buildgraph(infile);

    FILE *fp;
	fp=fopen(argv[6], "r"); //debug
	cut_data(fp,inputnum,outputnum,io_list1);
	fclose(fp);	
	fp=fopen(argv[8], "r"); //debug
	cut_data(fp,inputnum,outputnum,io_list2);
	fclose(fp);	
	fp=fopen(argv[10], "r"); //debug
	cut_data(fp,inputnum,outputnum,io_list3);
	fclose(fp);
	/*fp=fopen("./md5_1.dat", "r"); //debug
	cut_data(fp,inputnum,outputnum,io_list1);
	fclose(fp);	
	fp=fopen("./md5_2.dat", "r"); //debug
	cut_data(fp,inputnum,outputnum,io_list2);
	fclose(fp);	
	fp=fopen("./md5_3.dat", "r"); //debug
	cut_data(fp,inputnum,outputnum,io_list3);
	fclose(fp);*/
  	//cout<<"old state num:"<<statenum<<endl; 
	ans1.resize(ceil(128./(inputnum+outputnum)));
	ans2.resize(ceil(128./(inputnum+outputnum)));
	ans3.resize(ceil(128./(inputnum+outputnum)));
	for(int i=0;i<ans1.size();i++){ans1[i]=-1;}
	for(int i=0;i<ans2.size();i++){ans2[i]=-1;}
	for(int i=0;i<ans3.size();i++){ans3[i]=-1;}
	
	if(checkcompletegraph())
	{	fgraph<<"It is CSFSM!!"<<endl;
		//cout<<"It is CSFSM!!"<<endl;
	}
	else
	{
		
		processgraph_o(infile_o); 
		findexistedge(ans1,io_list1);
		newedge(ans1,io_list1); 
		findexistedge(ans2,io_list2);
		newedge(ans2,io_list2);
		findexistedge(ans3,io_list3);
		newedge(ans3,io_list3);

	//	cout<<"totalcost:"<<totalcost<<endl; 

		int dis1=0,dis2=0,dis3=0;
	/*	viewans(ans1,io_list1);
		cout<<endl<<"waytostart1:"<<BFS(startnum,dis1,ans1)<<endl<<endl;
		cout<<"way length1:"<<DectoHex(dis1)<<endl;
		viewans(ans2,io_list2);
		cout<<endl<<"waytostart2:"<<BFS(startnum,dis2,ans2)<<endl<<endl;
		cout<<"way length2:"<<DectoHex(dis2)<<endl;
		viewans(ans3,io_list3);
		cout<<endl<<"waytostart3:"<<BFS(startnum,dis3,ans3)<<endl<<endl;
		cout<<"way length3:"<<DectoHex(dis3)<<endl<<endl;*/
		
		fmd5_1i<<BFS(startnum,dis1,ans1)<<endl;
		fmd5_1e<<DectoHex(dis1)<<endl;
		fmd5_2i<<BFS(startnum,dis2,ans2)<<endl;
		fmd5_2e<<DectoHex(dis2)<<endl;
		fmd5_3i<<BFS(startnum,dis3,ans3)<<endl;
		fmd5_3e<<DectoHex(dis3)<<endl;
		
		if(inputnum<30)
		{
			map<string,int>::iterator iter; 
			int countcost=0;
			for(int i=0;i<statenum;i++)
			{
				for(int j=0;j<statenum;j++)
				{
					map<string,int> mapoutput;
					vector<vector<Node> >preinput;
					for(int k=0;k<graph[i][j].size();k++)
					{
						iter = mapoutput.find(graph[i][j][k].output);
						if(iter != mapoutput.end())
					    {				    	
					    	preinput[iter->second].push_back(graph[i][j][k]);
						}
					    else
					    {
					    	mapoutput[graph[i][j][k].output]=mapoutput.size()-1;
					    	preinput.resize(mapoutput.size());
					    	preinput[preinput.size()-1].push_back(graph[i][j][k]);
						}
					}
					for(int k=0;k<preinput.size();k++)
					{
						vector<Node> ans;
						vector<Node> inputdata;
						for(int m=0;m<preinput[k].size();m++)
						{
							inputdata.push_back(preinput[k][m]);	
						}
						Quine_McCluskey(inputdata,ans,inputnum);
						countcost+=ans.size();
						for(int m=0;m<ans.size();m++)
						{
							string word;
							word=ans[m].input+" S"+tostring(i)+" S"+tostring(j)+" "+ans[m].output;
							finalans.push_back(word);
						}
					}
				}
			}
			//cout<<endl<<".i "<<inputnum<<endl<<".o "<<outputnum<<endl<<".p "<<finalans.size()<<endl<<".s "<<statenum<<endl<<".r S"<<startnum<<endl;
			fgraph<<endl<<".i "<<inputnum<<endl<<".o "<<outputnum<<endl<<".p "<<finalans.size()<<endl<<".s "<<statenum<<endl<<".r S"<<startnum<<endl;
			for(int i=0;i<finalans.size();i++)
			{
				//cout<<finalans[i]<<endl;
				fgraph<<finalans[i]<<endl;
			}
		}
		else
		{
			int x=0;
			for(int i=0;i<statenum;i++)
			{
				if(i<graph_o.size())
					x+=graph_o[i].size();
				x+=graph_n[i].size();
			}
			fgraph<<endl<<".i "<<inputnum<<endl<<".o "<<outputnum<<endl<<".p "<<x<<endl<<".s "<<statenum<<endl<<".r S"<<startnum<<endl;
			//cout<<endl<<".i "<<inputnum<<endl<<".o "<<outputnum<<endl<<".p "<<x<<endl<<".s "<<statenum<<endl<<".r S"<<startnum<<endl;
			for(int i=0;i<statenum;i++)
			{
				for(int j=0;j<graph_o[i].size()&&i<graph_o.size();j++)
				{	//cout<<graph_o[i][j]<<endl;
					fgraph<<graph_o[i][j]<<endl;
				}
				for(int j=0;j<graph_n[i].size();j++)
				{   //cout<<graph_n[i][j]<<endl;
					fgraph<<graph_n[i][j]<<endl;
				}	
			}	
		}
		fgraph<<".e";
	}	
	infile.close();
	infile_o.close();
	fgraph.close(); 
	fmd5_1i.close();
	fmd5_1e.close();
	fmd5_2i.close();
	fmd5_2e.close();
	fmd5_3i.close();
	fmd5_3e.close();
	return 0;
}
////////////////////////////////////////////////////////////////
void recursive_call(string input,vector<vector<int> >& temparray,map<int,int>& mapvalue,int rownumber)
{
	int undefine=0;
	for(int i=0;i<input.size();i++)//for undefine input ex:1-1111  =101111  111111    start to recursive call
	{
		if(input.c_str()[i]=='-')
		{
			undefine=1;
			if(i==input.size()-1)
			{input=input.substr(0, i)+"0";}
			else
			{input=input.substr(0, i)+"0"+input.substr(i+1);	}
			recursive_call(input,temparray,mapvalue,rownumber);
			if(i==input.size()-1)
			{input=input.substr(0, i)+"1";}
			else
			{input=input.substr(0, i)+"1"+input.substr(i+1);}
			recursive_call(input,temparray,mapvalue,rownumber);
			return;
		}	
	}
	if(~undefine)//for specificed input
	{	
		temparray[rownumber][mapvalue[BintoDec(input)]]=1;
	}
}
void Quine_McCluskey(vector<Node>& inputdata,vector<Node>& ans,int& inputnum)
{
	vector<vector<Node> >datastore,templist;
	vector<Node> anslist;
	datastore.resize(inputnum+1);
	for(int i=0;i<inputdata.size();i++)
	{
		int count=0;
		for(int j=0;j<inputnum;j++)
		{
			if((inputdata[i].input).c_str()[j]=='1')
				count++;
		}
		inputdata[i].prime=true;
		datastore[count].push_back(inputdata[i]);
	}	
				
	int change=1;
	while(change)
	{
		templist.resize(datastore.size()-1);
		change=0;
		for(int i=0;i<datastore.size()-1;i++)
		{
			for(int j=0;j<datastore[i].size();j++)
			{
				for(int k=0;k<datastore[i+1].size();k++)
				{
					int position=-1,different=0; 
					for(int m=0;m<inputnum&&different<2;m++)
					{
						if((datastore[i][j].input).c_str()[m]!=(datastore[i+1][k].input).c_str()[m])
						{
							position=m;
							different++;
						}
					}
					if(different==1/*&&datastore[i][j].output==datastore[i+1][k].output*/)
					{
						change=1;
						int repeat=0;
						string word=datastore[i][j].input;
						word[position]='-';
						
						for(int m=0;m<templist[i].size();m++)
							if(templist[i][m].input==word)
							{	
								repeat=1; 
								datastore[i][j].prime=false;
								datastore[i+1][k].prime=false;
								break;
							}
						//cout<<(datastore[i][j].input)<<" "<<k<<" "<<repeat<<endl;	
						if(!repeat)
						{
							datastore[i][j].prime=false;
							datastore[i+1][k].prime=false;
							Node t;
							t.input=word;
							t.output=datastore[i][j].output;
							t.prime=true;
							templist[i].push_back(t);
						}
					}
				}
			}	
		}
		for(int i=0;i<datastore.size();i++)
		{
			for(int j=0;j<datastore[i].size();j++)
			{
				if(datastore[i][j].prime==true)
					anslist.push_back(datastore[i][j]);
			}
		}
		int length=datastore.size();
		datastore.clear();
		datastore.resize(length-1);
		for(int i=0;i<templist.size();i++)
		{
			for(int j=0;j<templist[i].size();j++)
			{
				datastore[i].push_back(templist[i][j]);
			}
		}
		templist.clear();
	}
	
	map<int,int> mapvalue;
    map<int,int>::iterator iter;
	for(int i=0;i<inputdata.size();i++)
	{
		iter = mapvalue.find(BintoDec(inputdata[i].input));
	    if(iter != mapvalue.end())
	    {		}
	    else
	    {
	    	mapvalue[BintoDec(inputdata[i].input)]=mapvalue.size()-1;
		}	
	}	
    
    vector<vector<int> >temparray;
    temparray.resize(anslist.size());
    for(int i=0;i<temparray.size();i++)
    	temparray[i].resize(mapvalue.size(),0);
    
	for(int i=0;i<anslist.size();i++)
	{
		recursive_call(anslist[i].input,temparray,mapvalue,i);	
	}	
    
	vector<int> columnbool;
	columnbool.resize(mapvalue.size(),0);
	vector<int> rowbool;
	rowbool.resize(anslist.size(),0);
	for(int i=0;i<mapvalue.size();i++)
	{
		int count=0;
		for(int j=0;j<anslist.size();j++)
		{
			if(temparray[j][i]==1)
				count++;
		}
		if(count==1)
		{
			for(int j=0;j<anslist.size();j++)
			{
				if(temparray[j][i]==1)
				{
					rowbool[j]=1;
					columnbool[i]=1;
					for(int k=0;k<mapvalue.size();k++)
					{
						if(temparray[j][k]==1)
							columnbool[k]=1;	
					}
					break;
				}
			}
		}
	}
	for(int i=0;i<columnbool.size();i++)
	{
		if(columnbool[i]==0)
		{
			int max=-1,rowposition=-1;
			for(int j=0;j<anslist.size();j++)
			{
				int count=0;
				if(temparray[j][i]==1)
				{
					for(int m=0;m<mapvalue.size();m++)
						if(temparray[j][m]==1&&columnbool[m]==0)
							count++;	
					if(count>max)
						rowposition=j;			
				}
			}
			rowbool[rowposition]=1;
			for(int j=0;j<mapvalue.size();j++)
			{
				if(temparray[rowposition][j]==1)
					columnbool[j]=1;
			}
		}
	}
	for(int i=0;i<rowbool.size();i++)
	{
		if(rowbool[i]==1)
			ans.push_back(anslist[i]);
	}
		
/*	cout<<endl<<endl;
	for(int i=0;i<rowbool.size();i++)
		cout<<rowbool[i]<<" ";
	cout<<endl<<endl;
	cout<<endl<<endl;
	for(int i=0;i<columnbool.size();i++)
		cout<<columnbool[i]<<" ";
	cout<<endl<<endl;
	for(int i=0;i<inputnum;i++)
		for(int j=0;j<datastore[i].size();j++)
			cout<<i<<" : "<<datastore[i][j].input<<"\n";*/
}

string BFS(int sourcenum,int& length,vector<int>& ans)//find way to start 
{
	string answay="";
	vector<int> prenode;//record 來源  紀錄路徑 
	vector<string> input;//record 來源input值  紀錄路徑  
	prenode.resize(graph.size(),-1);
	input.resize(graph.size());
	prenode[sourcenum]=-10;
	queue<int> q;
	q.push(sourcenum);
	while(!q.empty()&&prenode[ans[0]]==-1)
	{
		int u=q.front();
		for(int i=0;i<statenum;i++)
		{
			for(int j=0;j<statenum;j++)
			{
				if(graph[u][j].size()&&prenode[j]==-1)//有連到此點d 且此點尚無被經過
				{
					prenode[j]=u;
					input[j]=graph[u][j][0].input;
					q.push(j);
					break;
				}
			}				
		}
		q.pop();
	}

	int x=prenode[ans[0]];//起點的起點
	int y=ans[0];//起點
	while(x!=-10)//逆推回去路徑 
	{

		length++;
		string w1=input[y];//要到y 需在x輸入w1
			while(w1.size()<inputnum)
				w1="0"+w1;
				
		answay=w1+"_"+answay;
		y=x;
		x=prenode[x];
	}
	answay=answay.assign(answay,0,answay.size()-1);//將最後一個"_"丟掉 
	
	return answay;
}

void findexistedge(vector<int>& ans,vector<IONODE>& io_list)//part1 確認哪些現有邊為活邊 
{
	for(int i=0;i<ans.size();i++)//從每格答案邊尋找圖內相符邊 
	{
		int count,maxcount=-1,nextstate;
		if(ans[i]==-1)//尚未有答案 
		{
			string x=io_list[i].inbin;
			for(int currentstate=0;currentstate<statenum;currentstate++)//每個state的ans_input是否符合ans_output 
			{
				count=0;
				for(int m=0;m<statenum;m++)
				{
					for(int n=0;n<graph[currentstate][m].size();n++)
					{
						if(graph[currentstate][m][n].input==io_list[i].inbin&&graph[currentstate][m][n].output==io_list[i].outbin)//若符合則繼續往下連過去找 並計算長度最長邊 
						{
							vector<int> anstemp;
							count++;
							nextstate=m;
							int findnext=1;
							anstemp.push_back(currentstate);
							int nextstatewrong=0;
							while(count+i<ans.size()&&findnext)
							{
								findnext=0;
								for(int a=0;a<statenum;a++)
								{
									for(int b=0;b<graph[nextstate][a].size();b++)
									{
										if(graph[nextstate][a][b].input==io_list[i+count].inbin&&graph[nextstate][a][b].output==io_list[i+count].outbin)
										{
											findnext=1;	anstemp.push_back(nextstate);  nextstate=a;	count++; 
										}
										else if(graph[nextstate][a][b].input==io_list[i+count].inbin)
										{
											nextstatewrong=1;
										}
									}
								}
							} 
							if(maxcount<count&&nextstatewrong==0)
							{
								maxcount=count;
								for(int q=0;q<anstemp.size();q++)
									ans[i+q]=anstemp[q];			
							}
							else if(i==ans.size()-1)//for end
							{
								ans[i]=currentstate;
							}
						}
					}
				}
			
			}
		}
	}
}

void newedge(vector<int>& ans,vector<IONODE>& io_list)//part2 若找不到活邊則新增 
{
	for(int i=ans.size()-1;i>=0;i--)
	{
		if(ans[i]==-1)
		{
			int newvertex=1,findornot=0;
			for(int currentstate=0;currentstate<statenum;currentstate++)
			{
				findornot=0;
				for(int m=0;m<statenum&&findornot==0;m++)
				{
					for(int n=0;n<graph[currentstate][m].size();n++)
					{
						if(graph[currentstate][m][n].input==io_list[i].inbin)
						{	findornot=1; break;}
					}
				}
				if(!findornot)
				{
					string w;
					if(i==ans.size()-1)
						w =tostring(0);
					else
						w =tostring(ans[i+1]);
					string jj=tostring(currentstate);
					buildedge(io_list[i].inbin,"S"+jj,"S"+w,io_list[i].outbin); 
					graph_n[currentstate].push_back(io_list[i].inbin+" "+"S"+jj+" S"+w+" "+io_list[i].outbin);
					ans[i]=currentstate;
					totalcost++;
					newvertex=0;
					break;
				}
			}
			if(newvertex==1)//找不到現有空邊  則新增state
			{
				statenum++;
				graph_n.resize(statenum);
				graph.resize(statenum);
				for(int t=0;t<statenum;t++)//resize 新state
					graph[t].resize(statenum);

				totalcost++;//state++
				string tmp_des;
				if(i==ans.size()-1)//最後一個後面沒得指 default指回S0
					tmp_des =tostring(0);	
				else
					tmp_des =tostring(ans[i+1]);
				buildedge(io_list[i].inbin,"S"+tostring(statenum-1),"S"+tmp_des,io_list[i].outbin);
				graph_n[statenum-1].push_back(io_list[i].inbin+" "+"S"+tostring(statenum-1)+" S"+tmp_des+" "+io_list[i].outbin);
				ans[i]=statenum-1;
				totalcost++;
				if(i==0)//如 ans[0]=new vertex 則無路可到new vertex 需新增路徑 
				{
					int keepsearch=1,from=-1;string new_input="";
					for(int i=0;i<statenum&&keepsearch;i++)
					{
						int* temparray=new int[1<<inputnum];
						for(int j=0;j<statenum;j++)
						{
							for(int k=0;k<graph[i][j].size();k++)
							{
								temparray[BintoDec(graph[i][j][k].input)]=-1;
							}
						}
						for(int t=0;t<(1<<inputnum);t++)
						{
							if(temparray[t]!=-1)
							{
								keepsearch=0;
								from=i;
								new_input=DectoBin(t);
								while(new_input.size()<inputnum)//DectoBin出來 位數不一定和input相符 故補0
									new_input="0"+new_input;
								string new_output=DectoBin(0);//default output :0 並補齊位數
								while(new_output.size()<outputnum)
									new_output="0"+new_output;
								buildedge(new_input,"S"+tostring(i),"S"+tostring(statenum-1),new_output);
								graph_n[i].push_back(new_input+" S"+tostring(i)+" S"+tostring(statenum-1)+" "+new_output);
								totalcost++;
								break;
							}
						}
						delete[] temparray;
					}
				}
			}
		}	
	}	
}
/*************************************************************
  Purpose : change binary string to decimal int
  Input : binary string
  output: decimal int
*************************************************************/
int BintoDec(string word)
{
	int z=1,ans=0;
	for(int i=word.size()-1;i>=0;i--)
	{
		if(word.c_str()[i]=='1')
			ans+=z;
		z=z<<1;
	}
	return ans;
}
/*************************************************************
  Purpose : bulid an specific edge between two vertex
  Input : graph element
  output: void
*************************************************************/
void buildedge(string input,string from,string to,string output)
{
	int undefine=0;
	for(int i=0;i<input.size();i++)//for undefine input ex:1-1111  =101111  111111    start to recursive call
	{
		if(input.c_str()[i]=='-')
		{
			undefine=1;
			if(i==input.size()-1)
			{input=input.substr(0, i)+"0";}
			else
			{input=input.substr(0, i)+"0"+input.substr(i+1);	}
			buildedge(input,from,to,output);
			if(i==input.size()-1)
			{input=input.substr(0, i)+"1";}
			else
			{input=input.substr(0, i)+"1"+input.substr(i+1);}
			buildedge(input,from,to,output);
			return;
		}	
	}
	if(~undefine)//for specificed input
	{
		ss.clear();
		int fromnum,tonum;
		from=from.assign(from,1,from.size());
		ss<<from;
		ss>>fromnum;
		ss.clear();
		to=to.assign(to,1,to.size());
		ss<<to;
		ss>>tonum;
		Node temp;
		temp.input=input;
		temp.output=output;
		graph[fromnum][tonum].push_back(temp);
	}
}
/*************************************************************
  Purpose : change data to graph
  Input : graph data
  output: graph vector<vector<Node>>
*************************************************************/
vector<vector<vector <Node> > >&  buildgraph(ifstream& infile)
{
	graph.resize(statenum);
	for(int i=0;i<statenum;i++)
		graph[i].resize(statenum);
	
	string input,output,from,to;
	for(int i=0;i<termnum;i++)
	{
		infile>>input>>from>>to>>output; 
		buildedge(input,from,to,output);
	}	
	return graph;
}
/*************************************************************
  Purpose : show the state of graph (for demo)
  Input : graph vector<vector<Node>> 
  output: void
*************************************************************/
void viewgraph()
{
/*	for(int i=0;i<graph.size();i++)
	{
		cout<<"S"<<i<<" ";
		for(int j=0;j<graph[i].size();j++)
		{
			cout<<"des="<<graph[i][j].des<<" "<<"output="<<graph[i][j].output<<" ";
		}
		cout<<endl;
	}*/
}


/*************************************************************
  Purpose : convert hex_char to binary_char
  Input : hex char
  output: binary char
*************************************************************/
const char* hex_char_to_bin(char c)
{
     switch(toupper(c))
     {
             case '0': return "0000";
             case '1': return "0001";
             case '2': return "0010";
             case '3': return "0011";
             case '4': return "0100";
             case '5': return "0101";
             case '6': return "0110";
             case '7': return "0111";
             case '8': return "1000";
             case '9': return "1001";
             case 'A': return "1010";
             case 'B': return "1011";
             case 'C': return "1100";
             case 'D': return "1101";
             case 'E': return "1110";
             case 'F': return "1111";
     }
}

/*************************************************************
  Purpose : separate binary data into input and output list
  Input : binary data , input_number , output_number
  output: input_output_list (io_list)
*************************************************************/
void cut_data(FILE *fp, int in , int out,vector<IONODE>& io_list1)
{
	char hex_wm[32]="";    //hex water_mark data
	char bin_wm[128]="";  //binary water_mark data
	// hex 2 binary water mark
	fscanf(fp, "%s", &hex_wm);
	for( int i=0 ; i<32 ; i++)
	{
		char temp[4];
		strncpy(temp, hex_char_to_bin(hex_wm[i]), strlen(hex_char_to_bin(hex_wm[i])) + 1); 
		strcat(bin_wm,temp);
	} 
	
	int pad=128%(in+out);
	char* wm;
	wm=new char[128+in+out-pad];
	for(int i=0;i<128+in+out-pad;i++)
		wm[i]='0';

	
	//0 padding
	if(pad!=0) 
	{
		strcpy(wm,bin_wm);
		int pad_num=0;
		for (int i=pad ; i< in+out ; i++)
		{	
			wm[128+pad_num]='0';
			pad_num++;
		}
		wm[128+in+out-pad]='\0';
	}
	else
	{
		strcpy(wm,bin_wm);
		wm[128]='\0';
	}
	IONODE temp;
	for(int i=0 ; i<strlen(wm); i+=in+out)
	{
		temp.inbin.assign(wm+i,in);
		int k = i+in;
		temp.outbin.assign(wm+k,out);
		io_list1.push_back(temp);
	}
	delete wm;
}

void viewans(vector<int>& ans,vector<IONODE>& io_list)//traversal all ans 
{
	cout<<endl;
	for(int i=0;i<ans.size();i++)
		cout<<"ans "<<i<<" at state:"<<ans[i]<<" input:"<<io_list[i].inbin<<" output:"<<io_list[i].outbin<<endl;
}

int checkcompletegraph()//check input whether a complete graph
{
	int count=0;
	int complete=1;
	for(int i=0;i<statenum;i++)
	{
		count=0;
		for(int j=0;j<statenum;j++)
		{
			count+=graph[i][j].size();
		}
		if(inputnum<30&&count<(1<<inputnum))
		{	
			complete=0;
			break;
		}
		else if(inputnum>=30)//BUG when data extremely big
		{
			complete=0;
			break;
		}
	}
	return complete;
}
void processgraph_o(ifstream& infile)//record original graph
{
	int x;
	string word,word1,word2,word3,word0;
	infile>>word>>word>>word>>word>>word>>word>>word>>word>>word>>word;
	graph_o.resize(statenum);
	graph_n.resize(statenum);
	for(int i=0;i<termnum;i++)
	{
		infile>>word>>word0>>word2>>word3;
		word1=word0;
		word1=word1.assign(word1,1,word1.size());
		ss.clear();
		ss<<word1;
		ss>>x;
		graph_o[x].push_back(word+" "+word0+" "+word2+" "+word3);
	}
}

string DectoBin(int dec)//convert decimal to binary
{
	if ( dec == 0 ) return "0";
    if ( dec == 1 ) return "1";

    if ( dec % 2 == 0 )
        return DectoBin(dec / 2) + "0";
    else
        return DectoBin(dec / 2) + "1";
}

string DectoHex(int x)//convert decimal to Hex
{
	int a;
	string word="";
	if(x==0)
		word="0";
	while(x)
	{
		a=x%16;
		switch(a)
    	{
	        case 0: word="0"+word; break;
	        case 1: word="1"+word; break;
	        case 2: word="2"+word; break;
	        case 3: word="3"+word; break;
	        case 4: word="4"+word; break;
	        case 5: word="5"+word; break;
	        case 6: word="6"+word; break;
	        case 7: word="7"+word; break;
	        case 8: word="8"+word; break;
	        case 9: word="9"+word; break;
	        case 10: word="A"+word; break;
	        case 11: word="B"+word; break;
	        case 12: word="C"+word; break;
	        case 13: word="D"+word; break;
	        case 14: word="E"+word; break;
	        case 15: word="F"+word; break;
		}  
		x/=16;
	}
	while(word.size()<8)
		word="0"+word;
	return word;
}

string tostring(int x)
{
	int a;
	string word="";
	if(x==0)
		word="0";
	while(x)
	{
		a=x%10;
		switch(a)
    	{
	        case 0: word="0"+word; break;
	        case 1: word="1"+word; break;
	        case 2: word="2"+word; break;
	        case 3: word="3"+word; break;
	        case 4: word="4"+word; break;
	        case 5: word="5"+word; break;
	        case 6: word="6"+word; break;
	        case 7: word="7"+word; break;
	        case 8: word="8"+word; break;
	        case 9: word="9"+word; break;
		}  
		x/=10;
	}
	return word;
}

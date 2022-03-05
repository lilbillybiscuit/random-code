#include <bits/stdc++.h>

using namespace std;

struct Node {
    int id;
    vector<pair<int, Node*>> children;
    Node() {
    }
    Node(int id1) {
        id = id1;
    }
};
const int MAX_NODES=8;
vector<Node*> nodes;

vector<int> dist;
vector<int> path;
void dijkstras(int start, int destination) { //if you need to find the distance to every node then remove distance
    priority_queue<pair<int,int>, vector<pair<int, int>>, greater<pair<int,int>>> pq;

    bitset<100005> visited;
    dist.assign(100005, INT_MAX);
    path.assign(100005, -1);
    dist[start]=0;
    pq.push({0,start});
    while (!pq.empty()) {
        auto cur = pq.top(); pq.pop();
        int curdist = cur.first, curnode = cur.second;
        visited[curnode]=1;
        if (curdist > dist[curnode]) continue;
        //if (curnode == destination) return; //only if you need to stop at one node
        for (auto &nextedge: nodes[curnode]->children) {
            int nextweight = nextedge.first, nextnode = nextedge.second->id;
            if (!visited[nextnode] and dist[curnode]+nextweight < dist[nextnode]) {
                pq.push({dist[curnode]+nextweight, nextnode});
                dist[nextnode]= dist[curnode]+nextweight;
                path[nextnode] = curnode; //only if you need to keep track of the path of each node
            }
        }
    }
}

void connect(int node1, int node2, int weight) {
    nodes[node1]->children.push_back({weight, nodes[node2]});
    nodes[node2]->children.push_back({weight, nodes[node1]});
}

int main() {
    for (int i=0; i<MAX_NODES; i++) {
        Node* node = new Node(i);
        nodes.push_back(node);
    }
    connect(0,6,2555);
    connect(1,6,337);
    connect(1,2,1843);
    connect(6,2,1743);
    connect(6,5,1233);
    connect(5,2,802);
    connect(5,4,1387);
    connect(2,3,849);
    connect(4,3,142);
    connect(5,7,1120);
    connect(7,4, 1099);
    connect(3,7,1205);
    int start=0, finish=7;
    dijkstras(start, finish);
    int curnode = finish;
    while (curnode!=-1) {
        cout << curnode << endl;
        curnode = path[curnode];
    }
    //for (int i=0; i<MAX_NODES; i++) cout << i << ", " << dist[i]<< ", prevnode: " << path[i] << endl;
    int hi=0;
}

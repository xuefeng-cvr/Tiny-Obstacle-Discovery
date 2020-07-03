#include "mex.h"
#include "math.h"
#include <algorithm>
#include <vector>
using namespace std;
#define PI 3.14159265f
int clamp(int v, int a, int b)
{
    return v < a ? a : v > b ? b : v;
}

template <class T>
class Array
{
  public:
    Array()
    {
        _h = _w = 0;
        _x = 0;
        _free = 0;
    }
    virtual ~Array()
    {
        clear();
    }

    void clear()
    {
        if (_free)
            delete[] _x;
        _h = _w = 0;
        _x = 0;
        _free = 0;
    }
    void init(int h, int w) //??å§???ä¸?ä¸?h*w??T???°ç?
    {
        clear();
        _h = h;
        _w = w;
        _x = new T[h * w]();
        _free = 1;
    }
    T &val(size_t c, size_t r) //????
    {
        return _x[c * _h + r];
    }

    int _h, _w;
    T *_x;
    bool _free;
};

// convenient typedefs
typedef vector<float> vectorf; //vector?°ç?ï¼?????
typedef vector<int> vectori;
typedef Array<float> arrayf; //array?????°ç?
typedef Array<int> arrayi;

// bounding box data structures and routines
typedef struct
{
    int c, r, w, h;
    float s;               //å¾???
    float v[3];            //å­??¨å?????ä¸?ä¸??¨å??
} Box;                     //æ¯?ä¸?box??ä¸?ä¸?ç»???ä½?
typedef vector<Box> Boxes; //box list
bool boxesCompare(const Box &a, const Box &b)
{
    return a.s < b.s;
}

// main class for generating edge boxes
class EdgeBoxGenerator
{
  public:
    // method parameters (must be manually set)
    float _alpha, _beta, _minScore;
    int _maxBoxes;
    float _edgeMinMag, _edgeMergeThr, _clusterMinMag;
    float _maxAspectRatio, _minBoxArea, _gamma, _kappa;

    // main external routine (set parameters first)
    void generate(Boxes &boxes, arrayf &E, arrayf &O, arrayf &V);

  private:
    // edge segment information (see clusterEdges)
    int h, w;                   // image dimensions
    int _segCnt;                // total segment count
    arrayi _segIds;             // segment ids (-1/0 means no segment)
    vectorf _segMag;            // segment edge magnitude sums
    vectori _segR, _segC;       // segment lower-right pixel
    vector<vectorf> _segAff;    // segment affinities
    vector<vectori> _segAffIdx; // segment neighbors

    // data structures for efficiency (see prepDataStructs)
    arrayf _segIImg, _magIImg;
    arrayi _hIdxImg, _vIdxImg;
    vector<vectori> _hIdxs, _vIdxs;
    vectorf _scaleNorm;
    float _scStep, _arStep, _rcStepRatio;

    // data structures for efficiency (see scoreBox)
    arrayf _sWts;
    arrayi _sDone, _sMap, _sIds;
    int _sId;

    // helper routines
    void clusterEdges(arrayf &E, arrayf &O, arrayf &V);
    void prepDataStructs(arrayf &E);
    void scoreBox(Box &box);
    void scoreAllBoxes(Boxes &boxes);
};

////////////////////////////////////////////////////////////////////////////////

void EdgeBoxGenerator::generate(Boxes &boxes, arrayf &E, arrayf &O, arrayf &V)
{
    clusterEdges(E, O, V);
    prepDataStructs(E);
    // scoreBox(box);
    scoreAllBoxes(boxes);
}

void EdgeBoxGenerator::scoreAllBoxes(Boxes &boxes)
{
    // score all boxes, refine top candidates, perform nms
    int i, k = 0, m = int(boxes.size());
    for (i = 0; i < m; i++)
    {
        scoreBox(boxes[i]);
    }
}

void EdgeBoxGenerator::clusterEdges(arrayf &E, arrayf &O, arrayf &V)
{
    int c, r, cd, rd, i, j;
    h = E._h;
    w = E._w;

    // greedily merge connected edge pixels into clusters (create _segIds)
    _segIds.init(h, w); //edge segment??ç´¢å?
    _segCnt = 1;        //edge segment???°é??

    for (c = 0; c < w; c++)
        for (r = 0; r < h; r++)
        {
            if (c == 0 || r == 0 || c == w - 1 || r == h - 1 || E.val(c, r) <= _edgeMinMag) //?»é?¤å¼ºåº?å°?äº?0.1??è¾¹ç?pixel
                _segIds.val(c, r) = -1;
            else
                _segIds.val(c, r) = 0;
        }
    for (c = 1; c < w - 1; c++) //????æ¯?ä¸???ç´?ï¼??ºä??¹å??å¯?edgeè¿?è¡???å¹¶ï??´å?°æ?»å¼ºåº?å¤§ä???å¹¶é????
        for (r = 1; r < h - 1; r++)
        {
            if (_segIds.val(c, r) != 0)
                continue;

            float sumv = 0;
            int c0 = c, r0 = r;
            vectorf vs;
            vectori cs, rs;

            while (sumv < _edgeMergeThr)
            {
                _segIds.val(c0, r0) = _segCnt;
                float o0 = O.val(c0, r0), o1, v;
                bool found;
                for (cd = -1; cd <= 1; cd++)
                    for (rd = -1; rd <= 1; rd++)
                    {
                        if (_segIds.val(c0 + cd, r0 + rd) != 0)
                            continue;
                        found = false;
                        for (i = 0; i < cs.size(); i++)
                            if (cs[i] == c0 + cd && rs[i] == r0 + rd)
                            {
                                found = true;
                                break;
                            }
                        if (found)
                            continue;
                        o1 = O.val(c0 + cd, r0 + rd);
                        v = fabs(o1 - o0) / PI;
                        if (v > .5)
                            v = 1 - v;
                        vs.push_back(v);
                        cs.push_back(c0 + cd);
                        rs.push_back(r0 + rd);
                    }
                float minv = 1000;
                j = 0;
                for (i = 0; i < vs.size(); i++)
                    if (vs[i] < minv)
                    {
                        minv = vs[i];
                        c0 = cs[i];
                        r0 = rs[i];
                        j = i;
                    }
                sumv += minv;
                if (minv < 1000)
                    vs[j] = 1000;
            }
            _segCnt++;
        }

    // merge or remove small segments
    _segMag.resize(_segCnt, 0);
    for (c = 1; c < w - 1; c++)
        for (r = 1; r < h - 1; r++)
            if ((j = _segIds.val(c, r)) > 0)
                _segMag[j] += E.val(c, r);
    for (c = 1; c < w - 1; c++)
        for (r = 1; r < h - 1; r++)
            if ((j = _segIds.val(c, r)) > 0 && _segMag[j] <= _clusterMinMag)
                _segIds.val(c, r) = 0;
    i = 1;
    while (i > 0)
    {
        i = 0;
        for (c = 1; c < w - 1; c++)
            for (r = 1; r < h - 1; r++)
            {
                if (_segIds.val(c, r) != 0)
                    continue;
                float o0 = O.val(c, r), o1, v, minv = 1000;
                j = 0;
                for (cd = -1; cd <= 1; cd++)
                    for (rd = -1; rd <= 1; rd++)
                    {
                        if (_segIds.val(c + cd, r + rd) <= 0)
                            continue;
                        o1 = O.val(c + cd, r + rd);
                        v = fabs(o1 - o0) / PI;
                        if (v > .5)
                            v = 1 - v;
                        if (v < minv)
                        {
                            minv = v;
                            j = _segIds.val(c + cd, r + rd);
                        }
                    }
                _segIds.val(c, r) = j;
                if (j > 0)
                    i++;
            }
    }

    // compactify representation
    _segMag.assign(_segCnt, 0);
    vectori map(_segCnt, 0);
    _segCnt = 1;
    for (c = 1; c < w - 1; c++)
        for (r = 1; r < h - 1; r++)
            if ((j = _segIds.val(c, r)) > 0)
                _segMag[j] += E.val(c, r);
    for (i = 0; i < _segMag.size(); i++)
        if (_segMag[i] > 0)
            map[i] = _segCnt++;
    for (c = 1; c < w - 1; c++)
        for (r = 1; r < h - 1; r++)
            if ((j = _segIds.val(c, r)) > 0)
                _segIds.val(c, r) = map[j];

    // compute positional means and recompute _segMag
    _segMag.assign(_segCnt, 0);
    vectorf meanX(_segCnt, 0), meanY(_segCnt, 0);
    vectorf meanOx(_segCnt, 0), meanOy(_segCnt, 0), meanO(_segCnt, 0);
    for (c = 1; c < w - 1; c++)
        for (r = 1; r < h - 1; r++)
        {
            j = _segIds.val(c, r);
            if (j <= 0)
                continue;
            float m = E.val(c, r), o = O.val(c, r);
            _segMag[j] += m;
            meanOx[j] += m * cos(2 * o);
            meanOy[j] += m * sin(2 * o);
            meanX[j] += m * c;
            meanY[j] += m * r;
        }
    for (i = 0; i < _segCnt; i++)
        if (_segMag[i] > 0)
        {
            float m = _segMag[i];
            meanX[i] /= m;
            meanY[i] /= m;
            meanO[i] = atan2(meanOy[i] / m, meanOx[i] / m) / 2;
        }

    // compute segment affinities
    _segAff.resize(_segCnt);
    _segAffIdx.resize(_segCnt);
    for (i = 0; i < _segCnt; i++)
        _segAff[i].resize(0);
    for (i = 0; i < _segCnt; i++)
        _segAffIdx[i].resize(0);
    const int rad = 2;
    for (c = rad; c < w - rad; c++)
        for (r = rad; r < h - rad; r++)
        {
            int s0 = _segIds.val(c, r);
            if (s0 <= 0)
                continue;
            for (cd = -rad; cd <= rad; cd++)
                for (rd = -rad; rd <= rad; rd++)
                {
                    int s1 = _segIds.val(c + cd, r + rd);
                    if (s1 <= s0)
                        continue;
                    bool found = false;
                    for (i = 0; i < _segAffIdx[s0].size(); i++)
                        if (_segAffIdx[s0][i] == s1)
                        {
                            found = true;
                            break;
                        }
                    if (found)
                        continue;
                    float o = atan2(meanY[s0] - meanY[s1], meanX[s0] - meanX[s1]) + PI / 2;
                    float a = fabs(cos(meanO[s0] - o) * cos(meanO[s1] - o));
                    a = pow(a, _gamma);
                    _segAff[s0].push_back(a);
                    _segAffIdx[s0].push_back(s1);
                    _segAff[s1].push_back(a);
                    _segAffIdx[s1].push_back(s0);
                }
        }

    // compute _segC and _segR
    _segC.resize(_segCnt);
    _segR.resize(_segCnt);
    for (c = 1; c < w - 1; c++)
        for (r = 1; r < h - 1; r++)
            if ((j = _segIds.val(c, r)) > 0)
            {
                _segC[j] = c;
                _segR[j] = r;
            }

    // optionally create visualization (assume memory initialized is 3*w*h)
    if (V._x)
        for (c = 0; c < w; c++)
            for (r = 0; r < h; r++)
            {
                i = _segIds.val(c, r);
                V.val(c + w * 0, r) = i <= 0 ? 1 : ((123 * i + 128) % 255) / 255.0f;
                V.val(c + w * 1, r) = i <= 0 ? 1 : ((7 * i + 3) % 255) / 255.0f;
                V.val(c + w * 2, r) = i <= 0 ? 1 : ((174 * i + 80) % 255) / 255.0f;
            }
}

void EdgeBoxGenerator::prepDataStructs(arrayf &E)
{
    int c, r, i;

    // initialize step sizes
    _scStep = sqrt(1 / _alpha);
    _arStep = (1 + _alpha) / (2 * _alpha);
    _rcStepRatio = (1 - _alpha) / (1 + _alpha);

    // create _scaleNormï¼?box??å°ºåº¦ï¼?è®¡ç??å¾????¶ç????æ¯?
    _scaleNorm.resize(10000);
    for (i = 0; i < 10000; i++)
        _scaleNorm[i] = pow(1.f / i, _kappa);

    // create _segIImg
    arrayf E1;
    E1.init(h, w);
    for (i = 0; i < _segCnt; i++)
        if (_segMag[i] > 0)
        {
            E1.val(_segC[i], _segR[i]) = _segMag[i];
        }
    _segIImg.init(h + 1, w + 1);
    for (c = 1; c < w; c++)
        for (r = 1; r < h; r++) //edge groupå¼ºåº¦ç§?????
        {
            _segIImg.val(c + 1, r + 1) = E1.val(c, r) + _segIImg.val(c, r + 1) +
                                         _segIImg.val(c + 1, r) - _segIImg.val(c, r);
        }

    // create _magIImg
    _magIImg.init(h + 1, w + 1); //edge responseç§????¾ï?ç»?è¿????¼å???
    for (c = 1; c < w; c++)
        for (r = 1; r < h; r++)
        {
            float e = E.val(c, r) > _edgeMinMag ? E.val(c, r) : 0;
            _magIImg.val(c + 1, r + 1) = e + _magIImg.val(c, r + 1) +
                                         _magIImg.val(c + 1, r) - _magIImg.val(c, r);
        }

    // create remaining data structuresï¼?ä¸¤ç??°æ??ç»???
    _hIdxs.resize(h); //?¨ä?æ£?æµ?boxæ°´å¹³è¾¹ç??
    _hIdxImg.init(h, w);
    for (r = 0; r < h; r++) //æ¯?ä¸?è¡?
    {
        int s = 0, s1;
        _hIdxs[r].push_back(s);
        for (c = 0; c < w; c++) //æ¯?ä¸?è¡?å¯¹å???
        {
            s1 = _segIds.val(c, r);
            if (s1 != s)
            {
                s = s1;
                _hIdxs[r].push_back(s); //å¦?????segä¸?ä¸?ä¸?0ï¼?????
            }
            _hIdxImg.val(c, r) = int(_hIdxs[r].size()) - 1; //å¤§å?
        }
    }
    _vIdxs.resize(w); //?¨ä?æ£?æµ?boxç«??´è¾¹??
    _vIdxImg.init(h, w);
    for (c = 0; c < w; c++)
    {
        int s = 0;
        _vIdxs[c].push_back(s);
        for (r = 0; r < h; r++)
        {
            int s1 = _segIds.val(c, r);
            if (s1 != s)
            {
                s = s1;
                _vIdxs[c].push_back(s);
            }
            _vIdxImg.val(c, r) = int(_vIdxs[c].size()) - 1;
        }
    }

    // initialize scoreBox() data structures
    int n = _segCnt + 1;
    _sWts.init(n, 1);
    _sDone.init(n, 1);
    _sMap.init(n, 1);
    _sIds.init(n, 1);
    for (i = 0; i < n; i++)
        _sDone.val(0, i) = -1;
    _sId = 0;
}

void EdgeBoxGenerator::scoreBox(Box &box)
{
    int i, j, k, q, bh, bw, r0, c0, r1, c1, r0m, r1m, c0m, c1m;
    float *sWts = _sWts._x;
    int sId = _sId++;
    int *sDone = _sDone._x, *sMap = _sMap._x, *sIds = _sIds._x;
    // add edge count inside boxï¼???å­????¨ç??edgeè®¡æ??
    r1 = clamp(box.r + box.h, 0, h - 1); //(r0,c0),(r1,c1)
    r0 = box.r = clamp(box.r, 0, h - 1);
    c1 = clamp(box.c + box.w, 0, w - 1);
    c0 = box.c = clamp(box.c, 0, w - 1);
    bh = box.h = r1 - box.r;
    bh /= 2;
    bw = box.w = c1 - box.c;
    bw /= 2;
    float v1 = _segIImg.val(c0, r0) + _segIImg.val(c1 + 1, r1 + 1) - _segIImg.val(c1 + 1, r0) - _segIImg.val(c0, r1 + 1);
    // subtract middle quarter of edges
    float v2 = 0;
    r0m = r0 + bh / 2; //boxä¸??´é?¨å??ï¼??³å????
    r1m = r0m + bh;
    c0m = c0 + bw / 2;
    c1m = c0m + bw;
    v2 = _magIImg.val(c0m, r0m) + _magIImg.val(c1m + 1, r1m + 1) - _magIImg.val(c1m + 1, r0m) - _magIImg.val(c0m, r1m + 1);
    // short circuit computation if impossible to score highly
    float norm = _scaleNorm[bw + bh];
    box.s = (v1 - v2) * norm; //box??å§?å¾???
    if (box.s < _minScore)
    {
        box.s = 0;
        box.v[0] = 0;
        box.v[1] = 0;
        box.v[2] = 0;
        return;
    }
    // æ²?box???¡è¾¹??å¯»æ?¾ä?ä¹??¸äº¤??edge groub
    int cs, ce, rs, re, n = 0;
    cs = _hIdxImg.val(c0, r0);
    ce = _hIdxImg.val(c1, r0); // ä¸???
    for (i = cs; i <= ce; i++)
        if ((j = _hIdxs[r0][i]) > 0 && sDone[j] != sId) //ç´¢å?>0ï¼???edge group
        {
            sIds[n] = j;    //è®°å?edge groupç´¢å?
            sWts[n] = 1;    //è¡¨ç¤ºä»?è¾¹ç???°æ?¤è¾¹ç¼???è·?å¾??¸ä¼¼åº?ï¼???ä¸?edgeï¼???ä»¥ç?¸ä¼¼åº?ä¸?1
            sDone[j] = sId; //??è¯?ä½?ï¼?è¡¨ç¤ºè·?å¾??¸ä¼¼åº?å·²ç¡®å®?ï¼??°å??è¡¨ç¤ºboxç´¢å?
            sMap[j] = n++;  //è®¡æ??
        }
    cs = _hIdxImg.val(c0, r1);
    ce = _hIdxImg.val(c1, r1); // ä¸???
    for (i = cs; i <= ce; i++)
        if ((j = _hIdxs[r1][i]) > 0 && sDone[j] != sId)
        {
            sIds[n] = j;
            sWts[n] = 1;
            sDone[j] = sId;
            sMap[j] = n++;
        }
    rs = _vIdxImg.val(c0, r0);
    re = _vIdxImg.val(c0, r1); // å·?è¾?
    for (i = rs; i <= re; i++)
        if ((j = _vIdxs[c0][i]) > 0 && sDone[j] != sId)
        {
            sIds[n] = j;
            sWts[n] = 1;
            sDone[j] = sId;
            sMap[j] = n++;
        }
    rs = _vIdxImg.val(c1, r0);
    re = _vIdxImg.val(c1, r1); // ?³è¾¹
    for (i = rs; i <= re; i++)
        if ((j = _vIdxs[c1][i]) > 0 && sDone[j] != sId)
        {
            sIds[n] = j;
            sWts[n] = 1;
            sDone[j] = sId;
            sMap[j] = n++;
        }
    //æ²¿ç??è¿??¥è·¯å¾?(è½?å»?)è®¾ç½®?¸å?????w (w=1 means remove)
    for (i = 0; i < n; i++) //????æ¯?ä¸?ä¸?è¾¹æ??¸äº¤??edge group
    {
        float w = sWts[i];                              //????
        j = sIds[i];                                    //edge groupç´¢å?
        for (k = 0; k < int(_segAffIdx[j].size()); k++) //????ç¬?jä¸?edge group??affinity????
        {
            q = _segAffIdx[j][k];         // _segAffIdx?¸å?äº??»æ?¥ç?©é?µï?è¡¨ç¤ºjä¸???äº?edge group?¸è?
            float wq = w * _segAff[j][k]; //?¸ä¼¼åº?a(j,k)è¿?ä¹?ï¼?
            if (wq < .05f)
                continue;        // short circuit for efficiency
            if (sDone[q] == sId) //?°è¾¹ç¼?q??è·?å¾?å·²è?¡ç??è¿?
            {
                if (wq > sWts[sMap[q]]) //?°è·¯å¾??¸ä¼¼åº?å¤§ä??§è·¯å¾?
                {
                    sWts[sMap[q]] = wq;      //?´æ?°è·¯å¾??¸ä¼¼åº?
                    i = min(i, sMap[q] - 1); //?´æ??iï¼?è¿??·å???½ä?æ¬¡å¾ª??å°±æ²¿??å½???è·?å¾?ç»§ç»­å¯»æ?¾ä?ä¸?edge
                }
            }
            else if (_segC[q] >= c0 && _segC[q] <= c1 && _segR[q] >= r0 && _segR[q] <= r1) //????ifè¾¹ç?q(èµ·ç??)å¾?box??å»¶ä¼¸ä¸?è·?å¾??¸ä¼¼åº???è¢?è®¡ç??è¿?
            {
                sIds[n] = q;    //?´æ??edgeç´¢å?
                sWts[n] = wq;   //?´æ?°è·¯å¾??¸ä¼¼åº?(ä»?è¾¹ç???¸äº¤??edge??q??è·?å¾?(è½?å»?)???¸ä¼¼åº?è¿?ä¹?ä¹?ç§?)
                sDone[q] = sId; //??è¯?ä½?ï¼?è¡¨ç¤ºè·?å¾??¸ä¼¼åº?å·²è?¡ç??è¿?
                sMap[q] = n++;  //ç»§ç»­è®¡æ?°ï?????nè¡¨ç¤º????ä¸?boxè¾¹ç???¸è???edge seg
            }
        }
    } //??ç»?ä¼?å¾???box??æ¯?ä¸?edge??weightï¼??¶å¤§å°?ä¸ºä?boxè¾¹ç???°æ??edgeç»?????è½?å»??¸ä¼¼åº?(??å¤§ç?¸ä¼¼åº?ä¹?ç§?)
    // ???????»ä?boxè¾¹ç???¸äº¤??edge seg?????¨å??
    float v3 = 0;
    for (i = 0; i < n; i++) //????ä¸?boxè¾¹ç???¸äº¤??????edge seg
    {
        k = sIds[i];                                                              //edgeç´¢å?
        if (_segC[k] >= c0 && _segC[k] <= c1 && _segR[k] >= r0 && _segR[k] <= r1) //ä¸?boxè¾¹ç???¸äº¤??????edge seg
            v3 += sWts[i] * _segMag[k];
    }
    float vs = (v1 - v2 - v3) * norm;
    if (vs < _minScore)
        vs = 0;
    box.s = vs;
    box.v[0] = v1;
    box.v[1] = v2;
    box.v[2] = v3;
}

////////////////////////////////////////////////////////////////////////////////

// Matlab entry point: bbs = mex( E, O, prm1, prm2, ... )
void mexFunction(int nl, mxArray *pl[], int nr, const mxArray *pr[])
{
    // check and get inputs
    if (nr != 14)
        mexErrMsgTxt("Thirteen inputs required.");
    if (nl > 2)
        mexErrMsgTxt("At most two outputs expected.");
    if (mxGetClassID(pr[0]) != mxSINGLE_CLASS)
        mexErrMsgTxt("E must be a float*");
    if (mxGetClassID(pr[1]) != mxSINGLE_CLASS)
        mexErrMsgTxt("O must be a float*");

    arrayf E;
    E._x = (float *)mxGetData(pr[0]);
    arrayf O;
    O._x = (float *)mxGetData(pr[1]);

    int h = (int)mxGetM(pr[0]);
    O._h = E._h = h;
    int w = (int)mxGetN(pr[0]);
    O._w = E._w = w;

    // optionally create memory for visualization
    arrayf V;
    if (nl > 1)
    {
        size_t ds[3];
        ds[0] = h;
        ds[1] = w;
        ds[2] = 3;
        pl[1] = mxCreateNumericArray(3, ds, mxSINGLE_CLASS, mxREAL);
        V._x = (float *)mxGetData(pl[1]);
        V._h = h;
        V._w = w;
    }

    // setup and run EdgeBoxGenerator
    EdgeBoxGenerator edgeBoxGen;
    Boxes boxes;
    // vector<float> boxes;

    // è¯»å?¥å????
    edgeBoxGen._alpha = float(mxGetScalar(pr[2]));
    edgeBoxGen._beta = float(mxGetScalar(pr[3]));
    edgeBoxGen._minScore = float(mxGetScalar(pr[4]));
    edgeBoxGen._maxBoxes = int(mxGetScalar(pr[5]));
    edgeBoxGen._edgeMinMag = float(mxGetScalar(pr[6]));
    edgeBoxGen._edgeMergeThr = float(mxGetScalar(pr[7]));
    edgeBoxGen._clusterMinMag = float(mxGetScalar(pr[8]));
    edgeBoxGen._maxAspectRatio = float(mxGetScalar(pr[9]));
    edgeBoxGen._minBoxArea = float(mxGetScalar(pr[10]));
    edgeBoxGen._gamma = float(mxGetScalar(pr[11]));
    edgeBoxGen._kappa = float(mxGetScalar(pr[12]));
    float *bboxes_f = (float *)mxGetData(pr[13]);
    int num_box = mxGetM(pr[13]);

    pl[0] = mxCreateNumericMatrix(num_box, 8, mxSINGLE_CLASS, mxREAL);
    float *bbs = (float *)mxGetData(pl[0]);

    for (int i = 0; i < num_box; i++)
    {
        //         std::cout<<bboxes[i]<<" "<<bboxes[i+num_box]<<" "<<bboxes[i+num_box*2]<<" "<<bboxes[i+num_box*3]<< " "<<num_box<<std::endl;
        Box b;
        b.c = int(bboxes_f[i]) - 1;           //??
        b.r = int(bboxes_f[i + num_box]) - 1; //è¡?
        b.w = int(bboxes_f[i + num_box * 2]); //å®?
        b.h = int(bboxes_f[i + num_box * 3]); //é«?
        boxes.push_back(b);
    }
    // ?§è??½æ??
    edgeBoxGen.generate(boxes, E, O, V);

    // create output bbs and output to Matlab
    // ???°æ??å­??¥ä?ä¸??©é?µä¸­

    for (int i = 0; i <num_box; i++)
	{
		bbs[i + 0 * num_box] = (float)boxes[i].c + 1;
		bbs[i + 1 * num_box] = (float)boxes[i].r + 1;
		bbs[i + 2 * num_box] = (float)boxes[i].w;
		bbs[i + 3 * num_box] = (float)boxes[i].h;
		bbs[i + 4 * num_box] = boxes[i].s;
        bbs[i + num_box * 5] = boxes[i].v[0];
        bbs[i + num_box * 6] = boxes[i].v[1];
        bbs[i + num_box * 7] = boxes[i].v[2];
	}
}

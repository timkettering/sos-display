uniform vec2 input_resolution;
uniform float input_globalTime;
uniform float frequency;
uniform float amplitude;

#define USE_IQ_SMIN 0

float time;

float wlen=15.0;
float wc_scale=0.5;
float scroll;
float scene_scale=15.0;

// Finds the entry and exit points of a 2D ray with a circle of radius 1
// centered at the origin.
vec2 intersectCircle(vec2 ro, vec2 rd)
{
    float a = dot(rd, rd);
    float b = 2.0 * dot(rd, ro);
    float ds = b * b - 4.0 * a * (dot(ro, ro) - 1.0);

    if(ds < 0.0)
        return vec2(1e3);

    return ((-b - sqrt(ds) * vec2(-1.0, 1.0))) / (2.0 * a);
}

mat3 rotateXMat(float a)
{
    return mat3(1.0, 0.0, 0.0, 0.0, cos(a), -sin(a), 0.0, sin(a), cos(a));
}

mat3 rotateYMat(float a)
{
    return mat3(cos(a), 0.0, -sin(a), 0.0, 1.0, 0.0, sin(a), 0.0, cos(a));
}

// Adapted from https://www.shadertoy.com/view/ldlGR7
vec2 solve( vec2 p, float l1, float l2, float side )
{
    vec2 q = p*( 0.5 + 0.5*(l1*l1-l2*l2)/dot(p,p) );

    float s = l1*l1/dot(q,q) - 1.0;

    if( s<0.0 ) return vec2(-100.0);

    return q + q.yx*vec2(-1.0,1.0)*side*sqrt( s );
}

// Returns a pyramid-like periodic signal.
float pyramid(float x)
{
    x = fract(x);
    return min(x * 2.0, (1.0 - x) * 2.0);
}

// Returns a semicircular periodic signal.
float circ(float x)
{
    x = fract(x) * 2.0 - 1.0;
    return sqrt(1.0 - x * x);
}

#if USE_IQ_SMIN
float smin(float a,float b,float k){ return -log(exp(-k*a)+exp(-k*b))/k;}//from iq
#else
// http://www.johndcook.com/blog/2010/01/20/how-to-compute-the-soft-maximum/
float smin(in float a, in float b, in float k) { return a - log(1.0+exp(k*(a-b))) / k; }
#endif

float mp(float x)
{
    float y=0.3;
    return clamp((pyramid(x)-0.5)*2.0-0.4,-y,y);
}

float mosaic(vec3 p)
{
    // Disabled because it causes a compilation failure due to time-out or size limit.
    return 0.0;//max(mp(p.y*10.0),mp(p.z*10.0))*0.01;
}

mat3 transpose(mat3 m)
{
    return mat3(vec3(m[0].x,m[1].x,m[2].x),
                vec3(m[0].y,m[1].y,m[2].y),
                vec3(m[0].z,m[1].z,m[2].z));
}

vec2 unitSquareInterval(vec2 ro, vec2 rd)
{
    vec2 slabs0 = (vec2(+1.0) - ro) / rd;
    vec2 slabs1 = (vec2(-1.0) - ro) / rd;

    vec2 mins = min(slabs0, slabs1);
    vec2 maxs = max(slabs0, slabs1);

    return vec2(max(mins.x, mins.y),
                min(maxs.x, maxs.y));
}

vec3 squaresColours(vec2 p)
{
    p+=vec2(time*0.2);

    vec3 orange=vec3(1.0,0.4,0.1)*2.0;
    vec3 purple=vec3(1.0,0.2,0.5)*0.8;

    float l=pow(0.5+0.5*cos(p.x*7.0+cos(p.y)*8.0)*sin(p.y*2.0),4.0)*2.0;
    vec3 c=pow(l*(mix(orange,purple,0.5+0.5*cos(p.x*40.0+sin(p.y*10.0)*3.0))+
                  mix(orange,purple,0.5+0.5*cos(p.x*20.0+sin(p.y*3.0)*3.0))),vec3(1.2))*0.7;

    c+=vec3(1.0,0.8,0.4)*pow(0.5+0.5*cos(p.x*20.0)*sin(p.y*12.0),20.0)*2.0;

    c+=vec3(0.1,0.5+0.5*cos(p*20.0))*vec3(0.05,0.1,0.4).bgr*0.7;

    return c;
}

vec3 squaresTex(vec2 p,float border)
{
    float sm=0.02;
    vec2 res=vec2(8.0);
    vec2 ip=floor(p*res)/res;
    vec2 fp=fract(p*res);
    float m=1.0-max(smoothstep(border-sm,border,abs(fp.x-0.5)),smoothstep(border-sm,border,abs(fp.y-0.5)));
    m+=1.0-smoothstep(0.0,0.56,distance(fp,vec2(0.5)));
    return m*squaresColours(ip);
}

vec3 room(vec3 ro,vec3 rd,out vec3 rp,out vec3 n)
{
    vec2 box_size=vec2(1.0,5.0+3.0/8.0);

    vec2 cp=vec2(0.0),ct=vec2(1e3);

    for(int i=0;i<4;i+=1)
    {
        float cr=0.03;
        vec2 tcp=vec2(2.5/8.0*float(-1),float(i)-2.0+0.5/8.0);
        vec2 tct=intersectCircle((ro.xz-tcp)/cr,rd.xz/cr);

        if(tct.y > 0.0 && tct.y<ct.y)
        {
            ct=tct;
            cp=tcp;
        }
    }

    for(int i=0;i<4;i+=1)
    {
        float cr=0.03;
        vec2 tcp=vec2(2.5/8.0*float(+1),float(i)-2.0+0.5/8.0);
        vec2 tct=intersectCircle((ro.xz-tcp)/cr,rd.xz/cr);

        if(tct.y > 0.0 && tct.y<ct.y)
        {
            ct=tct;
            cp=tcp;
        }
    }

    ct.y=max(0.0,ct.y);

    vec3 ci=ro+rd*ct.y;
    vec2 cu=vec2(atan(ci.z-cp.y,ci.x-cp.x)/3.1415926*0.5,(ci.y+0.5/8.0)*4.0);

    float wt=max(0.0,unitSquareInterval(ro.xy * box_size, rd.xy * box_size).y);
    float t=min(ct.y,wt);

    rp=ro+rd*(t-1e-4);

    n.z=0.0;
    if(abs(rp.x*box_size.x)>abs(rp.y*box_size.y))
        n.xy=vec2(rp.x/abs(rp.x),0.0);
    else
        n.xy=vec2(0.0,rp.y/abs(rp.y));

    if(ct.y<wt)
    {
        n.y=0.0;
        n.xz=normalize(rp.xz-ci.xz);
    }

    float l=1.0-smoothstep(0.0,3.0,abs(rp.z-ro.z));

    vec3 wc=mix(squaresTex(rp.zy+vec2(0.0,0.5/8.0),0.5),squaresTex(rp.xz,0.44),step(0.999/box_size.y,abs(rp.y)));
    vec3 cc=squaresTex(cu,0.45)+0.8*vec3(smoothstep(0.83/5.0,0.86/5.0,abs(rp.y)));

    return l*mix(cc,wc,step(wt,t));
}

vec3 scene(vec2 p)
{
    mat3 cam = rotateXMat(cos(time * 0.2) * 0.1) * rotateYMat(time * 0.5);
    float lt=mod(time*wc_scale,wlen)/wlen;

    vec3 ro = cam*vec3(0.0,-0.15+lt*0.15, 0.15+lt*0.2)+vec3(0.0,0.0,scroll/scene_scale);
    vec3 rd = cam*vec3(p, -1.0);

    rd=normalize(rd);

    vec3 n,rp;

    vec3 c;
    vec3 c0=room(ro,rd,rp,n);

    vec3 r=reflect(rd,n);
    vec3 c1=room(rp,r,rp,n);
    c=c0+c1*c0*0.4;

    vec3 ll=vec3(1.0-(smoothstep(0.0,0.07,lt)-smoothstep(0.93,1.0,lt)));

    return ll+c+
        0.6*((sin(p.y)*cos(p.x+time*2.0)*0.5+0.5)*
             pow(mix(vec3(1.0,0.7,0.1),vec3(1.0,0.2,0.6),0.5+0.5*cos(p.x+sin(time*3.0+p.y*2.0))),vec3(2.0)));
}

void main()
{
    time=input_globalTime+1.0;
    scroll=-15.0+mod(time*wc_scale,wlen)*2.0;
    vec2 uv = gl_FragCoord.xy / input_resolution.xy;
    vec2 q=uv;
    vec2 t=uv*2.0-vec2(1.0);
    t.x*=input_resolution.x/input_resolution.y;
    gl_FragColor.rgb = scene(t.xy) * 1.3;

    // vignet
    gl_FragColor.rgb *= 0.5 + 0.5*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
}

%Space exploration

proposedR=1:10:200;
dfl=zeros(length(proposedR));
for i=1:length(proposedR)
[jinputs, ajam, apjam, jamchord, jamtwist, newhubRad] = jamieson_v2_02_tipdfl(crefjamiesonsCase, ...
            crefmoment, wndspeed, 0.33, 0.1, 0.5, crefnewhubRad, 3, jinputs, ...
            parentFolder, airfoils, proposedR(i));

[relWind, a, ap, amids, apmids, cpvector, ctvector, rmids, cmvector, cpmids, ...
            ctmids, cmmids, ocp, oct, ocm, dT, dQ, totalpwr, crefmoment, blade, D, R, F, L, Ks] = ...
            analysis_blocks_v2_02(jinputs, newhubRad, parentFolder, airfoils, 20);

dfl(i)=D(2,end);
powers(i)=totalpwr;
end

figure()
plot(proposedR,powers)
figure()
plot(proposedR,dfl)
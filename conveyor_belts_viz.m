%Messzelle
figure
s1 = 0:0.1:9;
for i = 1:length(s1)
    t1(i) = -(-69-sqrt(300*s1(i)+6))/150;
end
plot(t1,s1,'b','Linewidth',2)
hold on
s2 = 9:0.1:35;
for i = 1:length(s2)
    t2(i) = (s2(i) + 41.85)/62;
end
plot(t2,s2,'g--','Linewidth',2)
xlabel('\Deltat [s]')
ylabel('s [cm]')
legend('Aproximierte Anfahrtskurve', 'Aproximierte Förderkurve', 'Messpunkte')

plot(t_mess,s_mess,'ro','Linewidth',2)


%Isolierung
figure
s2 = 0:0.1:15;
for i = 1:length(s2)
    t2(i) = (3071+sqrt(25147041+157160000*s2(i)))/78580;
end
plot(t2,s2,'b','Linewidth',2)
hold on
s3 = 15:0.1:60;
for i = 1:length(s3)
%     t3(i) = 0.01623*s3(i) + 0.3929;
    t3(i) = (s3(i) + 22.96)/60.36;
end
plot(t3,s3,'g--','Linewidth',2)
hold on
plot(t_iso,s_iso,'ro','Linewidth',2)
xlabel('\Deltat [s]')
ylabel('s [cm]')
legend('Aproximierte Anfahrtskurve', 'Aproximierte Förderkurve', 'Messpunkte')
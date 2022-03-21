clc;clear;close all;
fid_in = fopen('m_sequence_input.txt','r');                                            
fid_out = fopen('m_sequence_output.txt','r');                                           
m_seq_in  = fscanf(fid_in,'%d');                                                    
m_seq_out = fscanf(fid_out,'%d');  
fclose(fid_in);
fclose(fid_out); 

N=754; n=1:N;
error = m_seq_in(1:N) - m_seq_out(1:N);
figure(); plot(n,m_seq_in(1:N),'b');    grid on;  xlabel('m sequence input'); ylabel('·ùÖµ');
figure(); plot(n,m_seq_out(1:N),'b');   grid on;  xlabel('m sequence output'); ylabel('·ùÖµ');
figure(); plot(n,error(1:N),'r');       grid on;  xlabel('error'); ylabel('·ùÖµ');

error_cnt = 0;
for cnt=1:N
    if(error(cnt)~=0)
        error_cnt = error_cnt + 1;
    end
end
error_rate = error_cnt/N
  

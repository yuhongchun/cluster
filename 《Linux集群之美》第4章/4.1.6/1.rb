newrecord("bid-east.example.net") do |query, answer|
    ips = ["54.175.1.2", "54.164.1.2", "52.6.1.2","54.164.1.2", "54.175.1.2","54.175.1.3","54.175.1.4","52.4.1.2"…… ]
    #bidder机器大约20台左右，公网IP作了无害处理
    ips = ips.randomize([1, 1, 1, 1, 1, 1, 1, 1])
    answer.shuffle false
    answer.ttl 30
    answer.content ips[0]
    answer.content ips[1]
    answer.content ips[2]
    answer.content ips[3]
    answer.content ips[4]
    answer.content ips[5]
    answer.content ips[6]
    answer.content ips[7]
end

module Pdns
    newrecord("ads.bilinmedia.net") do |query, answer|
        country_, region_ = country(query[:remoteip])
            answer.qclass query[:qclass]
            answer.qtype :A
            case country_
                when "US"
                    case region_
                        when "WI","IL","TN","MS","ID","KY","AL","OH","WV","VA","NC","SC","GA","FL","NY","PA","ME","VT","NH","MA","RI","CT","NJ","DE","MD","DC"
                        #东部地区用户访问东部图片服务器
                        answer.ttl 300
                        answer.content "54.165.1.2"
                        else
                        #西部地区用户访问西部图片服务器
                        answer.ttl 300
                        answer.content "54.67.1.2"
                    end
                else
                    #如果用户IP都不在上面的城市，则选择默认的西部机器
                    answer.ttl 300
                    answer.content "54.67.1.2"
        end
    end
end

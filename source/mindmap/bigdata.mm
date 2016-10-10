{
"meta":{
    "name":"大数据工程师必备技能",
    "author":"iou2much@sina.com",
    "version":"0.1"
},
"format":"node_tree",
"data":{"id":"root","topic":"大数据工程师必备技能","children":[
    {"id":"algorithm","topic":"通用算法基础","expanded":false,"direction":"right","children":[
        {"id":"ds","topic":"数据结构","children":[
            {"id":"ds1","topic":"栈 / 队列 / 链表"},
            {"id":"ds2","topic":"散列表"},
            {"id":"ds3","topic":"二叉树 / 红黑树 / B树"},
            {"id":"ds4","topic":"图"}
        ]},
        {"id":"al","topic":"常用算法","children":[
            {"id":"sort","topic":"排序","children":[
                {"id":"sort1","topic":"插入排序"},
                {"id":"sort2","topic":"桶排序"},
                {"id":"sort3","topic":"堆排序"},
                {"id":"sort4","topic":"快速排序"}
            ]},
            {"id":"al2","topic":"最大子数组"},
            {"id":"al3","topic":"最长公共序列"},
            {"id":"al4","topic":"最小生成树"},
            {"id":"al5","topic":"最短路径"},
            {"id":"al6","topic":"矩阵的存储和运算"}
        ]},
        {"id":"consistency","topic":"一致性","children":[
          {"id":"c1","topic":"paxos"},
          {"id":"c2","topic":"raft"},
          {"id":"c3","topic":"gossip"}
        ]}
    ]},
    {"id":"maths","topic":"数学","direction":"right","expanded":false,"children":[
        {"id":"calculus","topic":"微积分"},
        {"id":"linear-algebra","topic":"线性代数"},
        {"id":"propability","topic":"概率论"},
        {"id":"statistic","topic":"统计学"}
        {"id":"PGM","topic":"概率图模型","children":[
            {"id":"topic-model","topic":"主题模型"}
        ]}
    ]},
    {"id":"data-fetching","topic":"数据获取","direction":"right","expanded":false},
    {"id":"data-cleaning","topic":"数据清理","direction":"right","expanded":false},
    {"id":"machine-learning","topic":"机器学习","direction":"right","expanded":false,"children":[
        {"id":"essential","topic":"算法模型/理论方法","children":[
            {"id":"featuring","topic":"特征提取与处理"},
            {"id":"supervised-learning","topic":"监督学习"},
            {"id":"e8","topic":"贝叶斯分类"},
            {"id":"knn","topic":"K邻近"},
            {"id":"k-means","topic":"K-means"},
            {"id":"decision-tree","topic":"决策树"},
            {"id":"GDBT","topic":"GDBT"},
            {"id":"random-forest","topic":"随机森林"},
            {"id":"svm","topic":"支持向量机"},
            {"id":"boosting","topic":"Boosting","children":[
              {"id":"adaboost","topic":"AdaBoost"}
            ]},
            {"id":"regression","topic":"回归分析","children":[
              {"id":"logistic-regression","topic":"逻辑回归"},
              {"id":"linear-regression","topic":"线性回归"},
              {"id":"tree-regression","topic":"树回归"}
            ]},
            {"id":"unsupervised-learning","topic":"无监督学习","children":[
                {"id":"e1","topic":"聚类"}
            ]},
            {"id":"time-series","topic":"时间序列"},
            {"id":"arima","topic":"arima"},
            {"id":"e3","topic":"推荐系统"},
            {"id":"e7","topic":"支持向量机"},
            {"id":"perceptron","topic":"感知机"},
            {"id":"graph-model","topic":"图模型"},
            {"id":"e5","topic":"文本挖掘","children":[
                {"id":"NLP","topic":"自然语言处理"},
                {"id":"sentiment-analysis","topic":"情感分析"},
                {"id":"hmm","topic":"隐马尔可夫模型"},
                {"id":"em-algorithm","topic":"EM算法"},
                {"id":"conditional-random-fields","topic":"条件随机场"}
            ]},
            {"id":"dimensionality-reduction","topic":"降维","children":[
                {"id":"PCA","topic":"PCA"},
                {"id":"SVD","topic":"SVD"}
            ]},
            {"id":"optimizing-method","topic":"最优化","children":[
                {"id":"gradient-descent","topic":"梯度下降"},
                {"id":"Apriori","topic":"Apriori"},
                {"id":"FP-growth","topic":"FP-growth"},
                {"id":"Newtons-method","topic":"牛顿法"},
                {"id":"conjugated-descent","topic":"共轭梯度法"},
                {"id":"linear-search","topic":"线性搜索"},
                {"id":"confidence-domain-method","topic":"置信域方法"}
            ]},
            {"id":"reenforced-learning","topic":"强化学习","direction":"right","children":[
            ]}
        ]},
        {"id":"ml-tools","topic":"框架/工具","children":[
            {"id":"t1","topic":"Mahout"},
            {"id":"t2","topic":"Spark MLlib"},
            {"id":"t3","topic":"TensorFlow(Google系)"},
            {"id":"t4","topic":"Amazon Machine Learning"},
            {"id":"t5","topic":"DMTK(微软分布式机器学习工具)"}
        ]}
    ]},
    {"id":"deep-learning","topic":"深度学习","expanded":false,"direction":"right","children":[
        {"id":"e9","topic":"神经网络"},
        {"id":"bp-algorithm","topic":"bp算法"},
        {"id":"cnn","topic":"CNN"},
        {"id":"rnn","topic":"RNN"},
        {"id":"dl-tools","topic":"框架/工具","children":[
            {"id":"caffe","topic":"caffe"}
        ]}    
    ]},
    {"id":"cloud","topic":"云计算","direction":"right","expanded":false,"children":[
        {"id":"service","topic":"云服务","children":[
            {"id":"s1","topic":"SaaS"},
            {"id":"s2","topic":"PaaS"},
            {"id":"s3","topic":"IaaS"}
        ]},
        {"id":"openstack","topic":"Openstack"},
        {"id":"docker","topic":"Docker"}
    ]},
    {"id":"platform","topic":"大数据通用处理平台","direction":"left","expanded":false,"children":[
        {"id":"spark","topic":"Spark"},
        {"id":"flink","topic":"Flink"},
        {"id":"hadoop","topic":"Hadoop"}
    ]},
    {"id":"storage","topic":"分布式存储","direction":"left","expanded":false,"children":[
        {"id":"hdfs","topic":"HDFS"}
    ]},
    {"id":"resource","topic":"资源调度","direction":"left","expanded":false,"children":[
        {"id":"yarn","topic":"Yarn"},
        {"id":"mesos","topic":"Mesos"}
    ]},
    {"id":"dw","topic":"数据分析/数据仓库(SQL类)","direction":"left","expanded":false,"children":[
        {"id":"pig","topic":"Pig"},
        {"id":"hive","topic":"Hive"},
        {"id":"Kylin","topic":"Kylin"},
        {"id":"sparksql","topic":"Spark SQL"},
        {"id":"sparkdf","topic":"Spark DataFrame"},
        {"id":"impala","topic":"Impala"},
        {"id":"Phoenix","topic":"Phoenix"},
        {"id":"ELK","topic":"ELK"}
    ]},
    {"id":"mq","topic":"消息队列","direction":"left","expanded":false,"children":[
        {"id":"Kafka","topic":"Kafka"},
        {"id":"RocketMQ","topic":"RocketMQ"},
        {"id":"ZeroMQ","topic":"ZeroMQ"},
        {"id":"ActiveMQ","topic":"ActiveMQ"},
        {"id":"RabbitMQ","topic":"RabbitMQ"}
    ]},
    {"id":"datastream","topic":"流式计算","direction":"left","expanded":false,"children":[
        {"id":"Storm","topic":"Storm/JStorm"},
        {"id":"sparkstreaming","topic":"Spark Streaming"}
    ]},
    {"id":"log","topic":"日志收集","direction":"left","expanded":false,"children":[
        {"id":"scribe","topic":"Scribe"},
        {"id":"flume","topic":"Flume"}
    ]},
    {"id":"visual","topic":"数据可视化","direction":"right","expanded":false,"children":[
        {"id":"visual1","topic":"R"},
        {"id":"visual2","topic":"D3.js"},
        {"id":"visual3","topic":"ECharts"},
        {"id":"visual4","topic":"Excel"}
    ]},
    {"id":"language","topic":"编程语言","direction":"left","expanded":false,"children":[
        {"id":"Python","topic":"Python"},
        {"id":"R","topic":"R"},
        {"id":"Ruby","topic":"Ruby"},
        {"id":"java","topic":"Java"},
        {"id":"scala","topic":"Scala"}
    ]},
    {"id":"dig","topic":"数据分析挖掘","direction":"left","expanded":false,"children":[
        {"id":"matlab","topic":"MATLAB"},
        {"id":"spss","topic":"SPSS"},
        {"id":"sas","topic":"SAS"}
    ]}
]}
}

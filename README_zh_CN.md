# Logstash Input Plugin for Qingstor 

这是一个适配了[Qingstor](https://www.qingcloud.com/products/storage#qingstor), 工作在logstash中的input插件.  Qingstor是[Qingcloud](https://www.qingcloud.com/)推出的对象存储服务.  
作为一个input插件, 它能下载存储在Qingstor上的日志文件, 读入到logstash中进行进一步处理.  
详细功能参考下面配置说明.  

目前插件已经提交至rubygems.org, 使用以下命令安装:
```sh
    bin/logstash-plugin install logstash-input-qingstor
```
 手动安装本地代码, 安装方法参考下文.

## 1. 配置说明

#### 1.1 最小运行配置
- 使用'-f' 接受一个*.conf文件或者使用'-e'参数最小运行配置时, 至少需要以下三项
```sh
input {
    qingstor {
        access_key_id => 'your_access_key_id'           #required 
        secret_access_key => 'your_secret_access_key'   #required  
        bucket => 'bucket_name'                         #required 
        # region => "pek3a"                             #optional, default value "pek3a"                                
    }
}

```

#### 1.2 其他可选参数说明
```sh
input {
    qingstor {
        ......
        # 指定下载文件的前缀. 
        # 默认nil, 
        prefix => 'aprefix'

        # 本地保存临时文件的目录. 
        # 默认: 系统临时文件目录下的qingstor2logstash文件夹, 例如linux下 "/tmp/qingstor2logstash".
        tmpdir => '/local/temporary/directory' 

        # 是否在处理之后, 删除远程bucket中的文件.
        # 默认: false
        delete_remote_files => true

        # 重新配置qingstor的地址
        # 默认: nil
        host => "new.qingstor.net"

        # 重新配置qingstor地址的端口号
        # 默认: 443
        port => 443

        # 如果指定一个本地目录, 那么在处理完之后将文件备份至该位置.
        # 默认:　nil 
        local_dir => 'your/local/directory'

        # 如果指定了该值, 那么在处理完之后将文件上传到Qingstor指定的bucket中.
        # 默认: nil
        backup_bucket => 'backupbucket'

        # 配合上一项使用, 指定备份bucket所在的region.
        # 默认: "pek3a", 可选枚举值: ["pek3a", "sh1a"]
        backup_region => "sh1a"

        # 备份文件的前缀
        # 默认: nil 
        backup_prefix => "logstash/backup"

        # 指定一个sincedb的保存位置, sincedb用于记录上一次抓取文件的时间
        # 没有指定时默认在用户HOME目录下创建
        # 默认: nil
        sincedb_path => "~/qingstor/.sincedb" 

        # 每次抓取的时间间隔, 单位秒
        # 默认: 10(s)
        interval => 30
                                       
    }
}

```

## 2. 安装插件

#### 2.1 直接运行本地的插件

- 编辑Logstash目录下的Genfile, 添加插件的路径, 例如
```ruby
gem "logstash-input-qingstor", :path => "/your/local/logstash-input-qingstor"
```
- 安装插件
```sh
bin/logstash-plugin install --no-verify
```
- 使用插件运行
```sh
bin/logstash -e "input {qingstor {  access_key_id => 'your_access_key_id'            
        secret_access_key => 'your_secret_access_key'     
        bucket => 'bucket_name'                          }}'
```
此时你对插件所做的任意的代码上的修改都会直接生效.

#### 2.2 安装一个本地插件然后运行

这一步你需要生成一个插件的gem包, 然后通过logstash来安装到logstash的插件目录下
- 在logstash-input-qingstor项目目录下生成gem
```sh
gem build logstash-input-qingstor.gemspec
```
- 在Logstash的目录下使用logstash-plugin安装
```sh
bin/logstash-plugin install /your/local/plugin/logstash-input-qingstor.gem
```
- 安装完毕之后, 就可以使用Logstash运行开始测试了.


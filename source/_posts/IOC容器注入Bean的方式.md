---
title: IoC容器注入Bean的方式
author: Harrison
date: 2020-08-19 11:16:13
categories:
  - "Java"
tags:
  - "Spring"
  - "FactoryBean"
---

IOC容器注入Bean的方式，欢迎交流，指正错误。

<!-- more -->

Spring提供的主要功能就是对于Bean的管理，提供了多种方式可以向容器中注入Bean，下面总结一下向IOC容器注入Bean的几种方式（以下注入Bean的方式都是基于注解完成的）：



### 1. @ComponentScan+@Component方式

@ComponentScan可以扫描指定包下的类，如果该包下的类标有@Component、@Service、@Repository、@Controller、@RestController和@Configuration，都会被注入到IOC容器中，这种方式也是我们写代码最常用的，**一般针对自己写的类。**

 我们写的配置类，在上面标有@ComponentScan，指定扫描的的包，这时被扫描的类需要提供无参构造方法，不然会报错。

```java
@ComponentScan(basePackages = {"com.harrison"})
public class AppConfig {
 
}
```



若在 com.harrison 包下有User类，则在User类上添加@Component即可将User注入IOC容器。

```java
package com.harrison.pojo;
 
import org.springframework.stereotype.Component;
 
//使用这种方式需要替换无参构造的方法，因为spring是调用无参构造方法创建类的
@Component
public class User {
    
    private String name;
    private Integer age;
    
    public User() {
    }
 
    public User(String name, Integer age) {
        this.name = name;
        this.age = age;
    }
 	
    // Getter and Setter methods
 
}
```



### 2. 使用@Configuration + @Bean注解

该方法一般用于导入的第三方包里面的组件，因为第三方包里面没有添加Spring相关的注解，所以使用第一种方式就不行了。

```java
@Configuration
public class UserConfig {
 
    /**
     * 使用@Bean方式向容器注入Bean，适用于导入的第三方包里面的组件
     * 在@Bean后面不跟其他属性时，Bean的名称默认使用方法名
     * 在@Bean("user")， 如指定方法名，则使用定制的方法名
     * 在@Bean中还有initMethod属性和destroyMethod属性，可以指定初始话方法和销毁方法
     */
 
    @Bean("user")
    public User user(){
        return new User();
    }

```



### 3. 使用@Import注解

 该方法注入的Bean的id默认是组件的全类名 ，使用@Import就是将类注入到容器中，如果要注入的类没有被标注@Component也能被注入进来，一般注入的都是标注了@Configuration的配置类。

```java
/**
 * 该方式会将Bike类注入到容器中
 *
 * */
@Configuration
@Import({Bike.class})
public class Config {
 
}
 

public class Bike {
 
}
```



### 4. 实现ImportSelector接口来向容器注入bean

**注意：使用这种方式的话返回值不能为null，不然会出现空指针异常**

```java
/**
*使用@Import注解，是将MyImportSelector类注入到IOC容器中，至于它是不是ImportSelector的实现类，
*这个@Import注解是不进行判断的，在注入这个Bean后，有其他的组件会找到ImportSelector的实现类，并调
*用selectImports方法进行注册Bean
* */
 
@Configuration
@Import({MyImportSelector.class})
public class ImportConfig {
 
}
 
class MyImportSelector implements ImportSelector {
    /**
     * 返回值，就是到导入到容器中的组件全类名，返回值时一个字符串数组，可以导入多个bean
     * AnnotationMetadata:当前标注@Import注解的类的所有注解信息
     * */
    public String[] selectImports(AnnotationMetadata importingClassMetadata) {
        return new String[]{"com.harrison.User"};
    }
}
```



### 5. 实现ImportBeanDefinitionRegistrar接口来向容器注入Bean

这里的代码来自于DataSourceInitializedPublisher$Registrar类

```java
/**
 * {@link ImportBeanDefinitionRegistrar} to register the
 * {@link DataSourceInitializedPublisher} without causing early bean instantiation
 * issues.
 */
static class Registrar implements ImportBeanDefinitionRegistrar {
 
    private static final String BEAN_NAME = "dataSourceInitializedPublisher";
 
      /**
       * AnnotationMetadata：当前类的注解信息
       * BeanDefinitionRegistry:BeanDefinition注册类；
       *      把所有需要添加到容器中的bean；调用
       *      BeanDefinitionRegistry.registerBeanDefinition手工注册进来
       */
    @Override
    public void registerBeanDefinitions(AnnotationMetadata importingClassMetadata,
                                        BeanDefinitionRegistry registry) {
        if (!registry.containsBeanDefinition(BEAN_NAME)) {
            GenericBeanDefinition beanDefinition = new GenericBeanDefinition();
            beanDefinition.setBeanClass(DataSourceInitializedPublisher.class);
            beanDefinition.setRole(BeanDefinition.ROLE_INFRASTRUCTURE);
            // We don't need this one to be post processed otherwise it can cause a
            // cascade of bean instantiation that we would rather avoid.
            beanDefinition.setSynthetic(true);
            registry.registerBeanDefinition(BEAN_NAME, beanDefinition);
        }
    }
 
}
```



该方法可以有选择性的注入bean，传递的参数可以获取到IOC容器中关于bean的BeanDefinitionRegistry，使用这样方式比较灵活，在查看Spring源码时，大量使用了这种方式。

ImportBeanDefinitionRegistrar的实现类，必须是被@Import进行导入的，如@Import（Registrar .class）,如果不使用@Import注解导入Registrar类，而是使用一个@Component注解，将Registrar类通过扫描的方式放入到容器中，那么registerBeanDefinitions方法就不会被执行。

> @Import导入的原理：
>
> 处理这个@Import是在ConfigurationClassPostProcessor类中进行的，ConfigurationClassPostProcessor类会扫描出所有的对象，封装成beanDefinition对象，然后判断是否对象中是否加了@Import注解，加了的话判断是否为**ImportBeanDefinitionRegistrar**的实现类，如果是，则执行接口对象的方法（这只是见简单的说一下，其实步骤复杂的多，会有递归调用什么的，这里简单理解一下就行）**。**



### 6. 实现Factory Bean接口向容器注入Bean

**使用Spring提供的 FactoryBean（工厂Bean），默认获取到的是工厂bean调用getObject创建的对象，要获取工厂Bean本身，我们需要给id前面加一个&。**

```java
@Configuration
public class FactoryBeanConfig {
    /**
     * 在容器里面注入UserFactoryBean
     * 在获取userFactoryBean名称的Bean时，得到的是User类型的bean，如想要得到UserFactoryBean类型的bean，需要使用
     * AnnotationConfigApplicationContext context = new AnnotationConfigApplicationContext(FactoryBeanConfig.class);
     * String[] beanDefinitionNames = context.getBeanDefinitionNames("&userFactoryBean");  这种获取的是UserFactoryBean类型的bean
     * String[] beanDefinitionNames = context.getBeanDefinitionNames("userFactoryBean");  这种获取的是User类型的bean
     * */
    @Bean
    public UserFactoryBean userFactoryBean(){
        return new UserFactoryBean();
    }
}
 
public class UserFactoryBean implements FactoryBean {
 
    @Override
    public Object getObject() throws Exception {
        return new User();
    }
 
    @Override
    public boolean isSingleton() {
        return true;
    }
 
    @Override
    public Class<?> getObjectType() {
        return User.class;
    }
}
```


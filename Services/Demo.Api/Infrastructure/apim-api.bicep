param apimServiceName string

resource api 'Microsoft.ApiManagement/service/apis@2021-08-01' = {
  name: '${apimServiceName}/demo-api'
  properties: {
    description: ''
    authenticationSettings: {
      subscriptionKeyRequired: false
    }
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    apiRevision: '1'
    subscriptionRequired: false
    displayName: 'Demo API'
    path: 'demo'
    protocols: [
      'https'
    ]
  }
}

resource operation 'Microsoft.ApiManagement/service/apis/operations@2021-08-01' = {
  name: '${apimServiceName}/demo-api/account-get'
  dependsOn: [
    api
  ]
  properties: {
    displayName: 'Account'
    method: 'GET'
    urlTemplate: '/account'
    description: ''
    templateParameters: []
    responses: [
      {
        description: 'Test'
        headers: []
        representations: []
        statusCode: 200
      }
    ]
  }
}

resource policy 'Microsoft.ApiManagement/service/apis/operations/policies@2021-08-01' = {
  name: '${apimServiceName}/demo-api/account-get/policy'
  dependsOn: [
    operation
  ]
  properties: {
    value: '<policies>\r\n  <inbound>\r\n    <base />\r\n    <validate-jwt header-name="Authorization" failed-validation-httpcode="401" failed-validation-error-message="Unauthorized. Access token is missing or invalid.">\r\n      <openid-config url="https://login.microsoftonline.com/72f988bf-86f1-41af-91ab-2d7cd011db47/.well-known/openid-configuration" />\r\n      <required-claims>\r\n        <claim name="aud" match="any">\r\n          <value>api://0c9aa582-a623-4e1e-8dc0-b5aeee41b8d7</value>\r\n        </claim>\r\n        <claim name="appid" match="any">\r\n          <value>effeaebb-dfcb-468b-a321-52f919f46cdf</value>\r\n        </claim>\r\n      </required-claims>\r\n    </validate-jwt>\r\n    <rate-limit-by-key calls="25" renewal-period="60" counter-key="@(context.Request.IpAddress)" />\r\n    <ip-filter action="forbid">\r\n      <address>40.86.112.149</address>\r\n    </ip-filter>\r\n    <set-variable name="UserRoles" value="@(context.Request.Headers[&quot;Authorization&quot;].First().Split(\' \')[1].AsJwt()?.Claims[&quot;aud&quot;].FirstOrDefault())" />\r\n    <set-variable name="UserName" value="@(context.Request.Headers[&quot;Authorization&quot;].First().Split(\' \')[1].AsJwt()?.Claims[&quot;appid&quot;].FirstOrDefault())" />\r\n    <rate-limit-by-key calls="5" renewal-period="60" counter-key="@(context.Variables.GetValueOrDefault&lt;string&gt;(&quot;UserName&quot;))" />\r\n    <emit-metric name="api-ops-request" value="1" namespace="api-ops-metrics">\r\n      <dimension name="UserID" value="@(context.Variables.GetValueOrDefault&lt;string&gt;(&quot;UserName&quot;))" />\r\n      <dimension name="ClientIP" value="@(context.Request.IpAddress)" />\r\n      <dimension name="UserRoles" value="@(context.Variables.GetValueOrDefault&lt;string&gt;(&quot;UserRoles&quot;))" />\r\n      <dimension name="OperationName" value="@(context.Operation.Name)" />\r\n      <dimension name="OperationMethod" value="@(context.Operation.Method)" />\r\n    </emit-metric>\r\n    <choose>\r\n      <when condition="@(context.Variables.GetValueOrDefault&lt;string&gt;(&quot;UserRoles&quot;).Equals(&quot;api://0c9aa582-a623-4e1e-8dc0-b5aeee41b8d7&quot;))">\r\n        <return-response>\r\n          <set-status code="200" reason="OK" />\r\n          <set-header name="Content-Type" exists-action="override">\r\n            <value>application/json</value>\r\n          </set-header>\r\n          <set-body template="liquid">{\r\n                 "success": true,\r\n                 "ip-address": "{{context.Request.IpAddress}}",\r\n                 "user-roles": "{{context.Variables[\"UserRoles\"]}}",\r\n                 "user-name": "{{context.Variables[\"UserName\"]}}"\r\n                 }</set-body>\r\n        </return-response>\r\n      </when>\r\n      <otherwise>\r\n        <return-response>\r\n          <set-status code="403" reason="Forbidden" />\r\n        </return-response>\r\n      </otherwise>\r\n    </choose>\r\n  </inbound>\r\n  <backend>\r\n    <base />\r\n  </backend>\r\n  <outbound>\r\n    <base />\r\n  </outbound>\r\n  <on-error>\r\n    <base />\r\n  </on-error>\r\n</policies>'
    format: 'xml'
  }
}

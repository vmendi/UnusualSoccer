# To change this template, choose Tools | Templates
# and open the template in the editor.

puts "Hello World"

$address = 'http://mahouligachapas.unusualwonder.com/TestForm.aspx'
$address = 'http://apps.facebook.com/unusualsoccerlocal/'

$testName = 'Test06'

for i in 5...10

  $addressFinal = $address + '?FakeSessionKey=' + i.to_s + "&Test=" + $testName

  # Tiene que estar abierto ya porque si no, esto se queda esperando a que acabe el anterior
  system '"C:\Program Files (x86)\Mozilla Firefox\firefox.exe" ' + $addressFinal
  
  # system '"C:/Users/vmendi/AppData/Local/Google/Chrome/Application/chrome.exe" ' + $addressFinal
  
  #system '"C:\Program Files (x86)\Internet Explorer\iexplore.exe" ' + $addressFinal

end